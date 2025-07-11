import os
import re

# --- Configuration ---
POSTS_DIR = '_posts'
CATEGORY_DIR = 'category'
TAG_DIR = 'tag'

CATEGORY_TEMPLATE = """---
layout: category
title: {name}
category: {name}
slug: {name}
---
"""

TAG_TEMPLATE = """---
layout: tag
title: {name}
tag: {name}
---
"""

# --- Logic ---

def get_all_metadata_from_posts(posts_dir):
    """
    Parses all posts to extract categories and tags.
    """
    all_categories = set()
    all_tags = set()

    if not os.path.isdir(posts_dir):
        print(f"Error: Directory '{posts_dir}' not found.")
        return all_categories, all_tags

    for filename in os.listdir(posts_dir):
        if filename.endswith('.md'):
            filepath = os.path.join(posts_dir, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
                try:
                    front_matter_match = re.search(r'---\s*(.*?)\s*---', content, re.DOTALL)
                    if front_matter_match:
                        front_matter = front_matter_match.group(1)
                        
                        # Extract category
                        category_match = re.search(r'^\s*category:\s*(.*)', front_matter, re.MULTILINE)
                        if category_match:
                            category = category_match.group(1).strip()
                            if category:
                                all_categories.add(category)

                        # Extract tags
                        tags_match = re.search(r'^\s*tags:\s*\[(.*?)\]', front_matter, re.MULTILINE)
                        if tags_match:
                            tags_str = tags_match.group(1)
                            tags = [t.strip() for t in tags_str.split(',')]
                            all_tags.update(t for t in tags if t)
                except Exception as e:
                    print(f"Could not parse file {filename}: {e}")

    return all_categories, all_tags

def get_existing_pages(directory):
    """
    Gets a set of existing page names from a directory.
    """
    if not os.path.isdir(directory):
        os.makedirs(directory)
        return set()
        
    pages = set()
    for filename in os.listdir(directory):
        name = os.path.splitext(filename)[0]
        pages.add(name)
    return pages

def create_missing_pages(directory, template, found_items, existing_pages, item_type):
    """
    Creates missing pages for categories or tags.
    """
    count = 0
    for item in found_items:
        if item not in existing_pages:
            print(f"Found new {item_type}: {item}")
            
            if item_type == 'category':
                page_content = template.format(name=item)
                file_path = os.path.join(directory, f"{item}.html")
            else: # tag
                page_content = template.format(name=item)
                file_path = os.path.join(directory, f"{item}.md")

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(page_content)
            print(f"  -> Created {file_path}")
            count += 1
    return count

def main():
    """
    Main function to run the script.
    """
    print("Starting to scan for new categories and tags...")
    
    found_categories, found_tags = get_all_metadata_from_posts(POSTS_DIR)
    
    existing_categories = get_existing_pages(CATEGORY_DIR)
    existing_tags = get_existing_pages(TAG_DIR)
    
    print("-" * 20)
    
    print(f"Processing {len(found_categories)} unique categories...")
    num_new_categories = create_missing_pages(CATEGORY_DIR, CATEGORY_TEMPLATE, found_categories, existing_categories, 'category')
    if num_new_categories == 0:
        print("No new categories to create.")
        
    print("-" * 20)

    print(f"Processing {len(found_tags)} unique tags...")
    num_new_tags = create_missing_pages(TAG_DIR, TAG_TEMPLATE, found_tags, existing_tags, 'tag')
    if num_new_tags == 0:
        print("No new tags to create.")

    print("-" * 20)
    print("Script finished.")
    total_created = num_new_categories + num_new_tags
    if total_created > 0:
        print(f"Successfully created {total_created} new page(s).")
    else:
        print("Everything is up to date!")

if __name__ == "__main__":
    main()
