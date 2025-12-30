import json

# Read the JSON data
with open('pages_data.json', 'r', encoding='utf-8') as f:
    pages = json.load(f)

# Start building the seeds file
seeds_content = f'''# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     WhoknowsElixirMonolith.Repo.insert!(%WhoknowsElixirMonolith.SomeSchema{{}})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias WhoknowsElixirMonolith.Repo
alias WhoknowsElixirMonolith.Page
alias WhoknowsElixirMonolith.User

# Clear existing data (optional - comment out if you want to keep existing data)
Repo.delete_all(Page)
Repo.delete_all(User)

# Seed Pages
IO.puts("Seeding {len(pages)} pages...")

'''

# Add each page
for idx, page in enumerate(pages, 1):
    # Escape special characters for Elixir string
    content = page['content'].replace('\\', '\\\\').replace('"""', '\\"\\"\\"')
    title = page['title'].replace('"', '\\"')
    url = page['url'].replace('"', '\\"')

    # Parse datetime (format: YYYY-MM-DD HH:MM:SS)
    dt_parts = page['last_updated'].split(' ')
    date_part = dt_parts[0] if dt_parts else '2008-12-20'
    time_part = dt_parts[1] if len(dt_parts) > 1 else '00:00:00'

    seeds_content += f'''
# Page {idx}: {page['title']}
%Page{{
  title: "{title}",
  url: "{url}",
  language: "{page['language']}",
  last_updated: ~U[{date_part} {time_part}Z],
  content: """
{content}
"""
}} |> Repo.insert!()

'''

# Add users section
seeds_content += '''
IO.puts("✓ Pages seeded")

# Seed Users
IO.puts("Seeding users...")

# Note: The original password was stored as MD5 hash (5f4dcc3b5aa765d61d8327deb882cf99 = "password")
# The password for this admin user will be: "AdminPassword123!"
# Pre-hashed with PBKDF2 (100,000 rounds)
password_hash = "$pbkdf2-sha512$100000$yTmnVGqNcS4l5DwHwHiv1Q$bR0zpDLXDkEz7.kx8hKO4nHJxH.4hIy6TIJw0.7x8jM.0u0ggOVbSN.Qq0ILG3NwCLXMvOVpNq7KpOb.2wT4Fw"

%User{
  email: "keamonk@stud.kea.dk",
  name: "Admin",
  password_hash: password_hash,
  confirmed_at: ~U[2024-01-01 00:00:00Z]
} |> Repo.insert!()

IO.puts("✓ Users seeded")
IO.puts("\\n=== Seed data loaded successfully ===")
IO.puts("Admin user: keamonk@stud.kea.dk")
IO.puts("Admin password: AdminPassword123!")
IO.puts("Total pages: {len(pages)}")
IO.puts("=====================================\\n")
'''

# Write to seeds.exs
with open('priv/repo/seeds.exs', 'w', encoding='utf-8') as f:
    f.write(seeds_content)

print(f'✓ Generated seeds.exs with {len(pages)} pages')
