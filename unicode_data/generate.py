import re


def parse_unicode_data(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    categories = {}
    for line in lines:
        parts = line.strip().split(';')
        if len(parts) > 2:
            code_point = int(parts[0], 16)
            category = parts[2]

            if category not in categories:
                categories[category] = [(code_point, code_point)]
            else:
                last_range = categories[category][-1]
                if code_point == last_range[1] + 1:
                    categories[category][-1] = (last_range[0], code_point)
                else:
                    categories[category].append((code_point, code_point))

    return categories


def generate_dart_code(categories):
    dart_code = '// This file is generated automatically. Do not edit it.\n\n'
    dart_code += "import 'package:kiri_check/src/util/character/unicode.dart';\n\n"

    dart_code += 'enum UnicodeCategory {\n'
    keys = list(categories.keys())
    keys.sort()
    for category in keys:
        dart_code += f'  {category.lower()},\n'
    dart_code += '}\n\n'

    dart_code += 'const Map<UnicodeCategory, List<UnicodeRange>> unicodeCategories = {\n'
    for category in keys:
        ranges = categories[category]
        dart_code += f"  UnicodeCategory.{category.lower()}: ["
        dart_code += ',\n'.join(f'UnicodeRange(0x{start:X}, 0x{end:X})' for start, end in ranges)
        dart_code += ',],\n'
    dart_code += '};\n'
    return dart_code


def main():
    file_path = 'UnicodeData.txt'
    categories = parse_unicode_data(file_path)
    dart_code = generate_dart_code(categories)
    with open('unicode_data.dart', 'w', encoding='utf-8') as file:
        file.write(dart_code)


if __name__ == '__main__':
    main()
