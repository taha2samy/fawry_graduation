from flask import Flask, render_template, request, redirect, session, jsonify
from flaskext.mysql import MySQL
import os

app = Flask(__name__)
mysql = MySQL()

# MySQL configurations from environment variables
app.config['MYSQL_DATABASE_USER'] = os.getenv('MYSQL_DATABASE_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('MYSQL_DATABASE_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = os.getenv('MYSQL_DATABASE_DB')
app.config['MYSQL_DATABASE_HOST'] = os.getenv('MYSQL_DATABASE_HOST')

mysql.init_app(app)

# Set a secret key for the session
app.secret_key = 'why would I tell you my secret key?'

@app.route("/")
def main():
    return render_template('index.html')

@app.route('/showSignUp')
def showSignUp():
    return render_template('signup.html')

@app.route('/signUp', methods=['POST'])
def signUp():
    conn = None
    cursor = None
    try:
        _name = request.form['inputName']
        _email = request.form['inputEmail']
        _password = request.form['inputPassword']

        if _name and _email and _password:
            conn = mysql.connect()
            cursor = conn.cursor()
            cursor.callproc('sp_createUser', (_name, _email, _password))
            data = cursor.fetchall()

            if len(data) == 0:
                conn.commit()
                return jsonify({'message': 'User created successfully !'})
            else:
                return jsonify({'error': str(data[0])})
        else:
            return jsonify({'html': '<span>Enter the required fields</span>'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/showSignIn')
def showSignin():
    return render_template('signin.html')

@app.route('/validateLogin', methods=['POST'])
def validateLogin():
    con = None
    cursor = None
    try:
        _username = request.form['inputEmail']
        _password = request.form['inputPassword']

        con = mysql.connect()
        cursor = con.cursor()
        cursor.callproc('sp_validateLogin', (_username,))
        data = cursor.fetchall()

        if len(data) > 0:
            if data[0][3] == _password:
                session['user'] = data[0][0]
                return redirect('/userHome')
            else:
                return render_template('error.html', error='Wrong Email address or Password')
        else:
            return render_template('error.html', error='Wrong Email address or Password')

    except Exception as e:
        return render_template('error.html', error=str(e))
    finally:
        if cursor:
            cursor.close()
        if con:
            con.close()

@app.route('/userHome')
def userHome():
    if session.get('user'):
        return render_template('userHome.html')
    else:
        # It's also good practice to return 401 here
        return render_template('error.html', error='Unauthorized Access'), 401

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/')

@app.route('/showAddWish')
def showAddWish():
    # This page should also be protected
    if session.get('user'):
        return render_template('addWish.html')
    else:
        return render_template('error.html', error='Unauthorized Access'), 401

@app.route('/addWish', methods=['POST'])
def addWish():
    conn = None
    cursor = None
    try:
        if session.get('user'):
            _title = request.form['inputTitle']
            _description = request.form['inputDescription']
            _user = session.get('user')

            conn = mysql.connect()
            cursor = conn.cursor()
            cursor.callproc('sp_addWish', (_title, _description, _user))
            data = cursor.fetchall()

            if len(data) == 0:
                conn.commit()
                return redirect('/userHome')
            else:
                return render_template('error.html', error='An error occurred!')
        else:
            # The important change for the tests
            return render_template('error.html', error='Unauthorized Access'), 401
    except Exception as e:
        return render_template('error.html', error=str(e))
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/getWish')
def getWish():
    con = None
    cursor = None
    try:
        if session.get('user'):
            _user = session.get('user')

            con = mysql.connect()
            cursor = con.cursor()
            cursor.callproc('sp_GetWishByUser', (_user,))
            wishes = cursor.fetchall()

            wishes_dict = []
            for wish in wishes:
                wish_dict = {
                    'Id': wish[0],
                    'Title': wish[1],
                    'Description': wish[2],
                    'Date': wish[4]
                }
                wishes_dict.append(wish_dict)
            
            return jsonify(wishes_dict)
        else:
            # The important change for the tests
            return jsonify({'error': 'Unauthorized Access'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if con:
            con.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=True)