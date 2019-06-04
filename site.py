from flask import Flask, render_template, url_for, request
import os
app = Flask(__name__)

posts = [
    {
        'author': 'Corey Schafer',
        'title': 'Blog Post 1',
        'content': 'First post content',
        'date_posted': 'April 20, 2018'
    },
    {
        'author': 'Jane Doe',
        'title': 'Blog Post 2',
        'content': 'Second post content',
        'date_posted': 'April 21, 2018'
    }
]

PEOPLE_FOLDER = os.path.join('static', 'imgs')
app.config['UPLOAD_FOLDER'] = PEOPLE_FOLDER


@app.route("/")
@app.route("/home")
def home():
    return render_template('home.html', posts=posts)


@app.route("/about")
def about():
    return render_template('about.html', title='About')

@app.route("/floor1")
def floor1():
    return render_template('1floor.html', title='1st floor')

@app.route("/floor2")
def floor2():
    on_full_filename = os.path.join(app.config['UPLOAD_FOLDER'], 'html5.jpg')
    off_full_filename = os.path.join(app.config['UPLOAD_FOLDER'], 'html5.jpg')
    return render_template('2floor.html', title='2st floor',on_image=on_full_filename,off_image= off_full_filename )

@app.route("/toggle/<relay>")
def rel(relay):
    relay_string = relay + 'Praneeth'
    return relay_string

@app.route("/test")
def test():
    full_filename = os.path.join(app.config['UPLOAD_FOLDER'], 'html5.jpg')
    return render_template('test.html',user_image = full_filename)

@app.route("/<location>")
def switch(location):
    return location




if __name__ == '__main__':
    app.run(debug=True)