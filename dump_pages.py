import sqlite3
import json

conn = sqlite3.connect('whoknows.db')
cursor = conn.cursor()

# Get all pages data
cursor.execute('SELECT title, url, language, last_updated, content FROM pages')
pages_data = cursor.fetchall()

pages_list = []
for row in pages_data:
    pages_list.append({
        'title': row[0],
        'url': row[1],
        'language': row[2],
        'last_updated': row[3],
        'content': row[4]
    })

# Write to JSON file
with open('pages_data.json', 'w', encoding='utf-8') as f:
    json.dump(pages_list, f, indent=2, ensure_ascii=False)

print(f'Exported {len(pages_list)} pages to pages_data.json')

conn.close()
