import sys
import os

filename = "index.html"  # Specify the path to your index.html file

directory = "cypress"

html_document = '''
<!DOCTYPE html>
<html lang="en">

<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">
<title>Cypress Project List</title>

<style>
    .container {
        margin-top: 50px;
    }
    body {
        background-color: #f5f5f5;
        /* adjust the font */
        font-family: "Roboto", sans-serif;
    }
    ul {
        list-style-type: none;
    }
    li {
        margin-bottom: 10px;
    }
    /* style the list in material style */
    .list-group-item {
        padding: 20px;
        border: 1px solid #ddd;
        border-radius: 4px;
        background-color: #fff;
    }
</style>
</head>

<body>
<div class="container">
    <h3>Cypress Results</h3>
    <br/>
    <ul class="list-group">
    <a href="/cypress/results/mochawesome.html">Result Page</a>
    <!-- Insert here -->
    </ul>
</div>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
</body>

</html>'''




if os.path.exists(filename) == False:
    # Create the file if it doesn't exist
    with open(filename, "w") as file:
        file.write(html_document)



