import sys
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QTextEdit, QButtonGroup, 
                             QRadioButton, QGroupBox, QPushButton, QCheckBox,
                             QLineEdit, QLabel, QColorDialog, QScrollArea,
                             QDialog, QDialogButtonBox)
from PyQt6.QtCore import Qt, QRect
from PyQt6.QtGui import QPainter, QColor, QFont, QPen, QKeySequence, QShortcut

class AddTileDialog(QDialog):
    """Dialog for adding custom tiles"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Add Custom Tile")
        self.setModal(True)
        
        layout = QVBoxLayout()
        
        # Character input
        char_layout = QHBoxLayout()
        char_layout.addWidget(QLabel("Character:"))
        self.char_input = QLineEdit()
        self.char_input.setMaxLength(1)
        self.char_input.setPlaceholderText("Single char")
        char_layout.addWidget(self.char_input)
        layout.addLayout(char_layout)
        
        # Name input
        name_layout = QHBoxLayout()
        name_layout.addWidget(QLabel("Name:"))
        self.name_input = QLineEdit()
        self.name_input.setPlaceholderText("Tile name")
        name_layout.addWidget(self.name_input)
        layout.addLayout(name_layout)
        
        # Color picker
        color_layout = QHBoxLayout()
        color_layout.addWidget(QLabel("Color:"))
        self.color_btn = QPushButton("Choose Color")
        self.color_btn.clicked.connect(self.choose_color)
        self.selected_color = "#ff0000"
        self.color_btn.setStyleSheet(f"background-color: {self.selected_color};")
        color_layout.addWidget(self.color_btn)
        layout.addLayout(color_layout)
        
        # Dialog buttons
        button_box = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | 
            QDialogButtonBox.StandardButton.Cancel
        )
        button_box.accepted.connect(self.accept)
        button_box.rejected.connect(self.reject)
        layout.addWidget(button_box)
        
        self.setLayout(layout)
    
    def choose_color(self):
        color = QColorDialog.getColor()
        if color.isValid():
            self.selected_color = color.name()
            self.color_btn.setStyleSheet(f"background-color: {self.selected_color};")
    
    def get_tile_data(self):
        char = self.char_input.text()
        name = self.name_input.text() or char
        return char, name, self.selected_color


class GridCanvas(QWidget):
    """Canvas widget that handles all drawing and input"""
    def __init__(self, cols, rows, tiles, status_label):
        super().__init__()
        self.cols = cols
        self.rows = rows
        self.tiles = tiles
        self.cell_size = 20
        self.status_label = status_label
        
        # Set fixed size
        self.setFixedSize(self.cols * self.cell_size + 1, self.rows * self.cell_size + 1)
        
        # Grid data
        self.grid_data = [[' ' for _ in range(self.cols)] for _ in range(self.rows)]
        
        # Drawing state
        self.is_left_drawing = False
        self.is_right_drawing = False
        self.selected_tile = ' '
        
        # Current hover position for keyboard input
        self.hover_row = None
        self.hover_col = None
        
        # Enable mouse tracking and keyboard focus
        self.setMouseTracking(True)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
    
    def paintEvent(self, event):
        """Render the grid"""
        painter = QPainter(self)
        
        # Draw cells
        for row in range(self.rows):
            for col in range(self.cols):
                x = col * self.cell_size
                y = row * self.cell_size
                
                # Get tile
                tile_char = self.grid_data[row][col]
                
                # Use tile color if available, otherwise default
                if tile_char in self.tiles:
                    tile_name, tile_color = self.tiles[tile_char]
                else:
                    tile_color = '#2b2b2b'
                
                # Draw cell background
                painter.fillRect(x, y, self.cell_size, self.cell_size, QColor(tile_color))
                
                # Draw cell border
                painter.setPen(QPen(QColor('#000000'), 1))
                painter.drawRect(x, y, self.cell_size, self.cell_size)
                
                # Draw character if not empty
                if tile_char != ' ':
                    painter.setPen(QColor('#ffffff'))
                    painter.setFont(QFont('Arial', 10, QFont.Weight.Bold))
                    painter.drawText(QRect(x, y, self.cell_size, self.cell_size), 
                                   Qt.AlignmentFlag.AlignCenter, tile_char)
    
    def get_cell_from_pos(self, x, y):
        """Convert mouse position to grid cell"""
        col = x // self.cell_size
        row = y // self.cell_size
        
        if 0 <= row < self.rows and 0 <= col < self.cols:
            return row, col
        return None, None
    
    def update_status(self, row, col):
        """Update status label with current position info"""
        if row is not None and col is not None:
            self.hover_row = row
            self.hover_col = col
            index = row * self.cols + col
            char = self.grid_data[row][col]
            char_display = repr(char) if char != ' ' else "'Space'"
            self.status_label.setText(
                f"Row: {row}  Col: {col}  Index: {index}  Char: {char_display} (ASCII {ord(char)})  [Press any key to type]"
            )
        else:
            self.hover_row = None
            self.hover_col = None
            self.status_label.setText("Position: Outside grid")
    
    def mousePressEvent(self, event):
        """Handle mouse press"""
        row, col = self.get_cell_from_pos(event.pos().x(), event.pos().y())
        if row is not None and col is not None:
            if event.button() == Qt.MouseButton.LeftButton:
                self.is_left_drawing = True
                self.place_tile(row, col)
            elif event.button() == Qt.MouseButton.RightButton:
                self.is_right_drawing = True
                self.erase_tile(row, col)
    
    def mouseMoveEvent(self, event):
        """Handle mouse drag"""
        row, col = self.get_cell_from_pos(event.pos().x(), event.pos().y())
        self.update_status(row, col)
        
        if row is not None and col is not None:
            if self.is_left_drawing:
                self.place_tile(row, col)
            elif self.is_right_drawing:
                self.erase_tile(row, col)
    
    def mouseReleaseEvent(self, event):
        """Handle mouse release"""
        if event.button() == Qt.MouseButton.LeftButton:
            self.is_left_drawing = False
        elif event.button() == Qt.MouseButton.RightButton:
            self.is_right_drawing = False
    
    def leaveEvent(self, event):
        """Handle mouse leaving the widget"""
        self.hover_row = None
        self.hover_col = None
        self.status_label.setText("Position: Outside grid")
    
    def keyPressEvent(self, event):
        """Handle keyboard input to type characters at hover position"""
        # Check for Ctrl+V (paste/import)
        if event.key() == Qt.Key.Key_V and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            # Trigger import from parent
            if self.parent() and hasattr(self.parent(), 'import_from_string'):
                self.parent().import_from_string()
            return
        
        if self.hover_row is not None and self.hover_col is not None:
            text = event.text()
            if text and len(text) == 1 and text.isprintable():
                # Type the character at hover position
                self.grid_data[self.hover_row][self.hover_col] = text
                self.update()
                self.update_status(self.hover_row, self.hover_col)
    
    def place_tile(self, row, col):
        """Place selected tile"""
        if self.grid_data[row][col] != self.selected_tile:
            self.grid_data[row][col] = self.selected_tile
            self.update()
    
    def erase_tile(self, row, col):
        """Erase tile (make it empty)"""
        if self.grid_data[row][col] != ' ':
            self.grid_data[row][col] = ' '
            self.update()
    
    def set_selected_tile(self, char):
        """Update selected tile"""
        self.selected_tile = char
    
    def clear_all(self):
        """Clear entire grid"""
        self.grid_data = [[' ' for _ in range(self.cols)] for _ in range(self.rows)]
        self.update()
    
    def export_to_string(self):
        """Export grid to string"""
        result = ""
        for row in self.grid_data:
            result += ''.join(row)
        return result
    
    def export_to_rle_static(self, label_name="Level1RLE"):
        """Export to assembly static format"""
        text = self.export_to_string()
        if not text:
            return ""
        
        runs = []
        current_char = text[0]
        count = 1
        
        # Build runs list
        for char in text[1:]:
            if char == current_char and count < 65535:
                count += 1
            else:
                runs.append((count, current_char))
                current_char = char
                count = 1
        
        runs.append((count, current_char))
        
        total_memory = len(runs) * 2 + 1
        
        result = ["; RLE encoded level data"]
        result.append(f"{label_name} : var #{total_memory}  ; {len(runs)} runs, {total_memory} words total")
        result.append("")
        
        offset = 0
        for count, char in runs:
            result.append(f"static {label_name} + #{offset}, #{count}      ; count")
            result.append(f"static {label_name} + #{offset+1}, #{ord(char)}    ; '{char}' (ASCII {ord(char)})")
            offset += 2
        
        result.append(f"static {label_name} + #{offset}, #0      ; terminator")
        
        return '\n'.join(result)
    
    def import_from_string(self, text, start_row=None, start_col=None):
        """Import string to grid - supports multiline ASCII art with proper padding"""
        # If no start position specified, import to entire grid
        if start_row is None or start_col is None:
            start_row = 0
            start_col = 0
            full_grid_import = True
        else:
            full_grid_import = False
        
        # Handle multiline input (ASCII art)
        if '\n' in text:
            lines = text.split('\n')
            
            for line_idx, line in enumerate(lines):
                target_row = start_row + line_idx
                
                # Stop if we exceed grid height
                if target_row >= self.rows:
                    break
                
                # Place each character in the line
                for char_idx, char in enumerate(line):
                    target_col = start_col + char_idx
                    
                    # Stop if we exceed grid width
                    if target_col >= self.cols:
                        break
                    
                    self.grid_data[target_row][target_col] = char
        else:
            # Single line import
            if full_grid_import:
                # Old behavior: fill entire grid
                max_size = self.cols * self.rows
                
                # Pad with spaces if shorter than grid
                if len(text) < max_size:
                    text = text + ' ' * (max_size - len(text))
                
                # Truncate if longer than grid
                text = text[:max_size]
                
                for row in range(self.rows):
                    for col in range(self.cols):
                        idx = row * self.cols + col
                        char = text[idx] if idx < len(text) else ' '
                        self.grid_data[row][col] = char
            else:
                # Paste at cursor position
                char_idx = 0
                for row in range(start_row, self.rows):
                    for col in range(start_col if row == start_row else 0, self.cols):
                        if char_idx >= len(text):
                            break
                        self.grid_data[row][col] = text[char_idx]
                        char_idx += 1
                    if char_idx >= len(text):
                        break
        
        self.update()
        return True


class LevelEditor(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Sokoban Level Editor - Extended")
        self.setGeometry(100, 100, 1200, 800)
        
        # Grid dimensions
        self.cols = 40
        self.rows = 30
        
        # Default tiles
        self.tiles = {
            ' ': ('Empty', '#2b2b2b'),
            'b': ('Wall', '#8b4513'),
            '@': ('Box', '#ffa500'),
            'A': ('Player', '#00ff00'),
            'o': ('Goal', '#ffff00'),
            'B': ('Big Wall', '#654321'),
            '.': ('Floor', '#444444'),
        }
        
        self.init_ui()
        
    def init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)
        
        # Left side: Grid canvas and status
        left_layout = QVBoxLayout()
        
        # Status label for position info
        self.status_label = QLabel("Position: Hover over grid")
        self.status_label.setStyleSheet("""
            QLabel {
                background-color: #1e1e1e;
                color: #ffffff;
                padding: 5px;
                border: 1px solid #444444;
                font-family: Courier;
                font-size: 11px;
            }
        """)
        left_layout.addWidget(self.status_label)
        
        # Grid canvas
        self.grid_canvas = GridCanvas(self.cols, self.rows, self.tiles, self.status_label)
        left_layout.addWidget(self.grid_canvas)
        left_layout.addStretch()
        
        # Right side: Controls
        right_layout = QVBoxLayout()
        
        # Tile selector with scroll
        selector_group = QGroupBox("Tile Selector")
        selector_main_layout = QVBoxLayout()
        
        # Add custom tile button
        add_tile_btn = QPushButton("+ Add Custom Tile")
        add_tile_btn.clicked.connect(self.add_custom_tile)
        selector_main_layout.addWidget(add_tile_btn)
        
        # Scrollable tile list
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setMaximumHeight(300)
        
        tile_widget = QWidget()
        self.tile_layout = QVBoxLayout(tile_widget)
        
        self.tile_buttons = QButtonGroup()
        self.rebuild_tile_selector()
        
        scroll.setWidget(tile_widget)
        selector_main_layout.addWidget(scroll)
        selector_group.setLayout(selector_main_layout)
        right_layout.addWidget(selector_group)
        
        # Instructions
        instructions_group = QGroupBox("Instructions")
        instructions_layout = QVBoxLayout()
        
        label1 = QLabel("• Left-click and drag to paint tiles")
        label2 = QLabel("• Right-click and drag to erase")
        label3 = QLabel("• Add custom tiles for UI elements")
        label4 = QLabel("• Hover over grid to see position info")
        label5 = QLabel("• Press any key while hovering to type it")
        label6 = QLabel("• Ctrl+V to paste at hover position")
        
        for label in [label1, label2, label3, label4, label5, label6]:
            label.setWordWrap(True)
            instructions_layout.addWidget(label)
        
        instructions_group.setLayout(instructions_layout)
        right_layout.addWidget(instructions_group)
        
        # Action buttons
        actions_group = QGroupBox("Actions")
        actions_layout = QVBoxLayout()
        
        clear_btn = QPushButton("Clear All")
        clear_btn.clicked.connect(self.clear_grid)
        actions_layout.addWidget(clear_btn)
        
        self.rle_checkbox = QCheckBox("Use RLE Compression")
        self.rle_checkbox.toggled.connect(self.on_rle_toggle)
        actions_layout.addWidget(self.rle_checkbox)
        
        export_btn = QPushButton("Export to String")
        export_btn.clicked.connect(self.export_to_string)
        actions_layout.addWidget(export_btn)
        
        import_btn = QPushButton("Import from String (Ctrl+V)")
        import_btn.clicked.connect(self.import_from_string)
        actions_layout.addWidget(import_btn)
        
        # Add keyboard shortcut for import
        self.import_shortcut = QShortcut(QKeySequence("Ctrl+V"), self)
        self.import_shortcut.activated.connect(self.import_from_string)
        
        actions_group.setLayout(actions_layout)
        right_layout.addWidget(actions_group)
        
        # String output
        self.string_group = QGroupBox("Level String (up to 1200 chars)")
        string_layout = QVBoxLayout()
        
        self.string_output = QTextEdit()
        self.string_output.setFont(QFont("Courier", 9))
        self.string_output.setPlaceholderText("Level string will appear here...\nSupports multiline ASCII art - each line will be padded to grid width")
        string_layout.addWidget(self.string_output)
        
        self.string_group.setLayout(string_layout)
        right_layout.addWidget(self.string_group)
        
        main_layout.addLayout(left_layout, 3)
        main_layout.addLayout(right_layout, 1)
    
    def rebuild_tile_selector(self):
        """Rebuild the tile selector with current tiles"""
        # Clear existing buttons
        for button in self.tile_buttons.buttons():
            self.tile_buttons.removeButton(button)
            button.deleteLater()
        
        # Clear layout
        while self.tile_layout.count():
            item = self.tile_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        
        # Add all tiles
        for i, (char, (name, color)) in enumerate(sorted(self.tiles.items())):
            radio = QRadioButton(f"{name} ('{char}') - ASCII {ord(char)}")
            radio.setStyleSheet(f"QRadioButton::indicator:checked {{ background-color: {color}; border: 2px solid white; }}")
            radio.toggled.connect(lambda checked, c=char: self.select_tile(c) if checked else None)
            self.tile_buttons.addButton(radio, i)
            self.tile_layout.addWidget(radio)
            
            if char == ' ':
                radio.setChecked(True)
    
    def add_custom_tile(self):
        """Open dialog to add custom tile"""
        dialog = AddTileDialog(self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            char, name, color = dialog.get_tile_data()
            
            if not char:
                return
            
            # Add or update tile
            self.tiles[char] = (name, color)
            self.rebuild_tile_selector()
            self.grid_canvas.update()
    
    def select_tile(self, char):
        """Update selected tile in canvas"""
        self.grid_canvas.set_selected_tile(char)
    
    def clear_grid(self):
        """Clear entire grid"""
        self.grid_canvas.clear_all()
        self.string_output.clear()
    
    def on_rle_toggle(self, checked):
        """Update label when RLE is toggled"""
        if checked:
            self.string_group.setTitle("Level String (RLE Compressed)")
        else:
            self.string_group.setTitle("Level String (up to 1200 chars)")
    
    def export_to_string(self):
        """Export grid to string format"""
        if self.rle_checkbox.isChecked():
            result = self.grid_canvas.export_to_rle_static()
            original_size = self.cols * self.rows
            lines = result.split('\n')
            
            import re
            for line in lines:
                match = re.search(r'var #(\d+)', line)
                if match:
                    compressed_size = int(match.group(1))
                    compression_ratio = (1 - compressed_size / original_size) * 100
                    self.string_output.setPlainText(
                        f"; Original: {original_size} words, RLE: {compressed_size} words, saved {compression_ratio:.1f}%\n" +
                        result
                    )
                    return
            self.string_output.setPlainText(result)
        else:
            result = self.grid_canvas.export_to_string()
            self.string_output.setPlainText(result)
    
    def import_from_string(self):
        """Import string to grid - supports multiline ASCII art and paste at cursor"""
        text = self.string_output.toPlainText()
        
        # Skip RLE comment lines
        if text.startswith(';'):
            lines = text.split('\n', 1)
            if len(lines) > 1:
                text = lines[1]
            else:
                text = ""
        
        # Check if mouse is hovering over canvas
        start_row = None
        start_col = None
        paste_mode = False
        
        if self.grid_canvas.hover_row is not None and self.grid_canvas.hover_col is not None:
            start_row = self.grid_canvas.hover_row
            start_col = self.grid_canvas.hover_col
            paste_mode = True
        
        # Count lines for info message
        line_count = text.count('\n') + 1 if text else 0
        original_len = len(text)
        
        # Import with automatic padding/truncation and line handling
        self.grid_canvas.import_from_string(text, start_row, start_col)
        
        # Show info message
        max_len = self.cols * self.rows
        if paste_mode:
            if '\n' in text:
                self.string_output.append(f"\n✓ Pasted {line_count} lines at row {start_row}, col {start_col}")
            else:
                self.string_output.append(f"\n✓ Pasted {original_len} chars at row {start_row}, col {start_col}")
        else:
            if '\n' in text:
                self.string_output.append(f"\n✓ Imported {line_count} lines of ASCII art")
            elif original_len < max_len:
                self.string_output.append(f"\n✓ Imported {original_len} chars (padded to {max_len})")
            elif original_len > max_len:
                self.string_output.append(f"\n✓ Imported first {max_len} chars (truncated from {original_len})")
            else:
                self.string_output.append(f"\n✓ Imported {original_len} chars")


if __name__ == '__main__':
    app = QApplication(sys.argv)
    app.setStyle('Fusion')
    editor = LevelEditor()
    editor.show()
    sys.exit(app.exec())
