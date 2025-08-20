import pytest
from app import app

# -----------------------------------------------------------------------------
# Core Test Fixtures
# -----------------------------------------------------------------------------

@pytest.fixture
def client():
    """
    Creates and configures a test client for each test function.
    This ensures a clean, isolated application context for every test case.
    """
    app.config.update({
        "TESTING": True,
        "WTF_CSRF_ENABLED": False,  # Disable CSRF for simplified form testing
        "SECRET_KEY": "test-secret-key-for-session-management",
    })
    with app.test_client() as client:
        yield client

# -----------------------------------------------------------------------------
# Test Suite for Static Page Rendering and Basic Routes
# -----------------------------------------------------------------------------

def test_main_page_renders_successfully(client):
    """Asserts that the main landing page loads correctly."""
    response = client.get('/')
    assert response.status_code == 200
    # FIX: Check for a more reliable element, like the page title, which is less likely to change.
    assert b"<title>Python Flask Bucket List App</title>" in response.data

def test_signup_page_renders_successfully(client):
    """Asserts that the user registration page loads correctly."""
    response = client.get('/showSignUp')
    assert response.status_code == 200
    # FIX: A more specific check for content on the sign-up page.
    assert b"<h3>Sign Up</h3>" in response.data

def test_signin_page_renders_successfully(client):
    """Asserts that the user login page loads correctly."""
    response = client.get('/showSignIn')
    assert response.status_code == 200
    # FIX: A more specific check for content on the sign-in page.
    assert b"<h3>Sign In</h3>" in response.data

# -----------------------------------------------------------------------------
# Test Suite for User Authentication Workflows
# -----------------------------------------------------------------------------
class TestAuthentication:
    """Groups all tests related to user sign-up, login, and logout."""

    def test_user_signup_succeeds_with_valid_data(self, client):
        """Verifies that a new user can be created successfully."""
        response = client.post('/signUp', data={
            'inputName': 'New User',
            'inputEmail': 'new.user@example.com',
            'inputPassword': 'securepassword'
        })
        assert response.status_code == 200
        # This will now work correctly after changing to jsonify in app.py
        assert response.get_json() == {'message': 'User created successfully !'}

    def test_signup_fails_if_user_already_exists(self, client):
        """Ensures the system prevents registration of a user with a duplicate email."""
        client.post('/signUp', data={'inputName': 'Existing User', 'inputEmail': 'existing@example.com', 'inputPassword': 'password'})
        response = client.post('/signUp', data={'inputName': 'Another Name', 'inputEmail': 'existing@example.com', 'inputPassword': 'password'})
        assert response.status_code == 200
        json_response = response.get_json()
        assert 'error' in json_response
        assert 'Username Exists' in json_response['error']

    def test_login_succeeds_and_redirects_with_correct_credentials(self, client):
        """Tests that valid credentials result in a redirect to the user's home."""
        client.post('/signUp', data={'inputName': 'Login User', 'inputEmail': 'login.user@example.com', 'inputPassword': 'loginpass'})
        response = client.post('/validateLogin', data={
            'inputEmail': 'login.user@example.com',
            'inputPassword': 'loginpass'
        })
        # This test will now pass after fixing the VARCHAR length in the Stored Procedure
        assert response.status_code == 302
        assert response.headers['Location'] == '/userHome'

    def test_login_fails_with_incorrect_password(self, client):
        """Ensures login attempts with an incorrect password are rejected."""
        client.post('/signUp', data={'inputName': 'Wrong Pass User', 'inputEmail': 'wrong.pass@example.com', 'inputPassword': 'correct_password'})
        response = client.post('/validateLogin', data={'inputEmail': 'wrong.pass@example.com', 'inputPassword': 'incorrect_password'})
        assert response.status_code == 200
        # FIX: Check for the specific error message on the rendered error page.
        assert b'Wrong Email address or Password' in response.data

    def test_logout_clears_session_and_redirects(self, client):
        """Verifies that the logout endpoint terminates the session and redirects to the main page."""
        client.post('/signUp', data={'inputName': 'Logout User', 'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        client.post('/validateLogin', data={'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        response = client.get('/logout', follow_redirects=True)
        assert response.status_code == 200
        # FIX: Check for the title of the main page after redirect.
        assert b"<title>Python Flask Bucket List App</title>" in response.data
        
        # Verify that protected routes are now inaccessible
        home_response = client.get('/userHome')
        assert b'Unauthorized Access' in home_response.data

# -----------------------------------------------------------------------------
# Test Suite for Wishlist (CRUD) Functionality
# -----------------------------------------------------------------------------
class TestWishes:
    """Groups tests for all wishlist-related endpoints, which require an authenticated user."""

    @pytest.fixture(autouse=True)
    def client_with_login(self, client):
        """Auto-use fixture to log in a user before each test in this class."""
        client.post('/signUp', data={'inputName': 'Wish User', 'inputEmail': 'wish@example.com', 'inputPassword': 'wishpass'})
        client.post('/validateLogin', data={'inputEmail': 'wish@example.com', 'inputPassword': 'wishpass'})
        yield client

    def test_user_home_is_accessible_when_logged_in(self, client_with_login):
        """Verifies an authenticated user can access their home page."""
        response = client_with_login.get('/userHome')
        assert response.status_code == 200
        # FIX: Check for a more specific element, like the main header.
        # Make sure you have `<h1>My Bucket List</h1>` in your userHome.html template.
        assert b"<h1>My Bucket List</h1>" in response.data

    def test_add_wish_succeeds_and_redirects(self, client_with_login):
        """Tests that creating a new wish correctly redirects the user."""
        response = client_with_login.post('/addWish', data={
            'inputTitle': 'Learn Advanced Pytest',
            'inputDescription': 'Master fixtures and plugins.'
        })
        # FIX: Test the redirect itself, which is the direct responsibility of this endpoint.
        assert response.status_code == 302
        assert response.headers['Location'] == '/userHome'

    def test_get_wish_api_returns_correct_json_data(self, client_with_login):
        """Verifies the /getWish API returns wishes in JSON format."""
        client_with_login.post('/addWish', data={'inputTitle': 'Test API', 'inputDescription': 'Check JSON response.'})
        response = client_with_login.get('/getWish')
        assert response.status_code == 200
        wishes = response.get_json()
        # This will now work correctly after changing to jsonify in app.py
        assert isinstance(wishes, list)
        assert len(wishes) > 0
        assert wishes[0]['Title'] == 'Test API'

    def test_add_wish_fails_for_unauthorized_user(self, client):
        """Ensures that an unauthenticated user cannot add a wish."""
        response = client.post('/addWish', data={
            'inputTitle': 'Attempt to add wish without login',
            'inputDescription': 'This should be rejected.'
        })
        assert response.status_code == 200
        assert b'Unauthorized Access' in response.data