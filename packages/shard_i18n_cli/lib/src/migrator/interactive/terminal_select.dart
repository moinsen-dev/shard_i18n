import 'dart:io';

/// A custom terminal selection menu component.
/// Provides arrow-key navigation when ANSI escapes are supported,
/// with automatic fallback to numbered selection.
class Select {
  final String prompt;
  final List<String> options;
  final int initialIndex;

  Select({required this.prompt, required this.options, this.initialIndex = 0})
    : assert(options.isNotEmpty, 'Options list cannot be empty'),
      assert(
        initialIndex >= 0 && initialIndex < options.length,
        'Initial index must be within options range',
      );

  /// Displays the selection menu and returns the index of the chosen option.
  int interact() {
    // Use arrow-key navigation if terminal supports it
    if (stdout.supportsAnsiEscapes && stdin.hasTerminal) {
      return _interactiveSelect();
    }
    // Otherwise fall back to numbered selection
    return _fallbackSelect();
  }

  /// Interactive selection using arrow keys and ANSI escape codes.
  int _interactiveSelect() {
    var selectedIndex = initialIndex;
    final stdinEchoMode = stdin.echoMode;
    final stdinLineMode = stdin.lineMode;

    try {
      // Configure terminal for raw input
      stdin.echoMode = false;
      stdin.lineMode = false;

      // Hide cursor
      stdout.write('\x1B[?25l');

      // Draw initial menu
      _drawMenu(selectedIndex);

      // Process input
      while (true) {
        final key = stdin.readByteSync();

        if (key == 27) {
          // Escape sequence (arrow keys)
          final next1 = stdin.readByteSync();
          final next2 = stdin.readByteSync();

          if (next1 == 91) {
            if (next2 == 65) {
              // Up arrow
              if (selectedIndex > 0) {
                selectedIndex--;
                _drawMenu(selectedIndex);
              }
            } else if (next2 == 66) {
              // Down arrow
              if (selectedIndex < options.length - 1) {
                selectedIndex++;
                _drawMenu(selectedIndex);
              }
            }
          }
        } else if (key == 10 || key == 13) {
          // Enter key
          break;
        } else if (key == 3) {
          // Ctrl+C
          _cleanup();
          exit(0);
        }
      }

      // Clear the menu
      _clearMenu();

      // Show the selection
      stdout.writeln('$prompt ${options[selectedIndex]}');

      return selectedIndex;
    } finally {
      // Restore terminal settings
      stdin.echoMode = stdinEchoMode;
      stdin.lineMode = stdinLineMode;
      stdout.write('\x1B[?25h'); // Show cursor
    }
  }

  /// Draws the menu with the current selection highlighted.
  void _drawMenu(int selectedIndex) {
    // Move cursor to start of menu
    if (selectedIndex != initialIndex || stdout.terminalLines > 0) {
      stdout.write('\x1B[${options.length + 1}A'); // Move up
      stdout.write('\x1B[G'); // Move to column 0
    }

    // Draw prompt
    stdout.writeln(prompt);

    // Draw options
    for (var i = 0; i < options.length; i++) {
      stdout.write('\x1B[K'); // Clear line
      if (i == selectedIndex) {
        // Highlighted option (inverted colors)
        stdout.write('\x1B[7m> ${options[i]}\x1B[0m');
      } else {
        // Normal option
        stdout.write('  ${options[i]}');
      }
      stdout.writeln();
    }
  }

  /// Clears the menu from the terminal.
  void _clearMenu() {
    // Move cursor up and clear lines
    for (var i = 0; i <= options.length; i++) {
      stdout.write('\x1B[A'); // Move up
      stdout.write('\x1B[K'); // Clear line
    }
    stdout.write('\x1B[G'); // Move to column 0
  }

  /// Cleanup on exit.
  void _cleanup() {
    _clearMenu();
    stdout.write('\x1B[?25h'); // Show cursor
    stdout.writeln('\nAborted.');
  }

  /// Fallback selection using numbered input (for non-ANSI terminals).
  int _fallbackSelect() {
    // Display prompt and options
    stdout.writeln(prompt);
    for (var i = 0; i < options.length; i++) {
      stdout.writeln('  ${i + 1}. ${options[i]}');
    }

    // Get user input
    while (true) {
      stdout.write('Enter choice (1-${options.length}): ');
      final input = stdin.readLineSync();

      if (input == null) {
        // EOF or Ctrl+D
        stdout.writeln('\nAborted.');
        exit(0);
      }

      final choice = int.tryParse(input.trim());
      if (choice != null && choice >= 1 && choice <= options.length) {
        return choice - 1;
      }

      stdout.writeln(
        'Invalid choice. Please enter a number between 1 and ${options.length}.',
      );
    }
  }
}
