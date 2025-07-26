import os

def count_dart_lines(directory="."):
    total_lines = 0
    dart_files = 0

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                dart_files += 1
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        line_count = sum(1 for _ in f)
                        total_lines += line_count
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")

    print(f"\nTotal .dart files: {dart_files}")
    print(f"Total lines of Dart code: {total_lines}")

if __name__ == "__main__":
    count_dart_lines()
