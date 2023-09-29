
import os
from datetime import datetime

exclude_files = ['./generate_links.py', './index.html']
exclude_folders = ['./downloads', './e2e', './results/assets', './support', './fixtures']

def generate_file_links(directory):
    file_links = []
    for entry in os.listdir(directory):
        entry_path = os.path.join(directory, entry)
        if os.path.isfile(entry_path) and entry_path not in exclude_files:
            file_link = f'<li class="list-group-item"><a href="{entry_path}">{entry_path}</a></li>'
            file_links.append(file_link)
        elif os.path.isdir(entry_path) and entry_path not in exclude_folders:
            subdirectory_links = generate_file_links(entry_path)
            file_links.extend(subdirectory_links)
    return file_links

def generate_html_document(directory ):
    file_links = generate_file_links(directory)
    # get current time in string format of yyyy-MM-dd HH:mm:ss
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    html_content = '\n'.join(file_links)
    html_document = f'''
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">
        <title>Artifacts from latest pipeline execution</title>
    </head>
    <body>
        <div class="container" style="margin-top:50px">
            <h3>Artifacts from pipeline execution - {current_time} </h3>
            <ul class="list-group">
                {html_content}
            </ul>
        </div>

        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
    </body>
</html>
    '''
    return html_document

# Provide the directory path you want to generate the HTML for
directory_path = '.'  # Use '.' for the current directory

html = generate_html_document(directory_path)

# Write the HTML document to a file
with open('index.html', 'w') as file:
    file.write(html)

