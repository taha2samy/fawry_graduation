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
        "WTF_CSRF_ENABLED": False,
        "SECRET_KEY": "test-secret-key-for-session-management",
    })
    with app.test_client() as client:
        yield client

# -----------------------------------------------------------------------------
# Test Suite for Static Page Rendering
# -----------------------------------------------------------------------------

def test_main_page_renders_successfully(client):
    """Asserts that the main landing page (index.html) loads correctly."""
    response = client.get('/')
    assert response.status_code == 200
    # FIX: Check for the unique "Sign up today" button from index.html
    assert b'href="showSignUp"' in response.data
    assert b'Sign up today' in response.data

def test_signup_page_renders_successfully(client):
    """Asserts that the user registration page (signup.html) loads correctly."""
    response = client.get('/showSignUp')
    assert response.status_code == 200
    # FIX: Check for the unique "Sign up" button from signup.html
    assert b'<button id="btnSignUp"' in response.data

def test_signin_page_renders_successfully(client):
    """Asserts that the user login page (signin.html) loads correctly."""
    response = client.get('/showSignIn')
    assert response.status_code == 200
    # FIX: Check for the unique "Sign in" button from signin.html
    assert b'<button id="btnSignIn"' in response.data

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
        assert response.status_code == 302
        assert response.headers['Location'] == '/userHome'

    def test_login_fails_with_incorrect_password(self, client):
        """Ensures login attempts with an incorrect password are rejected."""
        client.post('/signUp', data={'inputName': 'Wrong Pass User', 'inputEmail': 'wrong.pass@example.com', 'inputPassword': 'correct_password'})
        response = client.post('/validateLogin', data={'inputEmail': 'wrong.pass@example.com', 'inputPassword': 'incorrect_password'})
        assert response.status_code == 200
        # The error page renders the error message inside an h1 tag.
        assert b'<h1>Wrong Email address or Password</h1>' in response.data

    def test_logout_clears_session_and_redirects(self, client):
        """Verifies that the logout endpoint terminates the session and redirects to the main page."""
        client.post('/signUp', data={'inputName': 'Logout User', 'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        client.post('/validateLogin', data={'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        response = client.get('/logout', follow_redirects=True)
        assert response.status_code == 200
        assert b"Sign up today" in response.data  # Should be on the main page
        
        home_response = client.get('/userHome')
        # The error page renders the error message inside an h1 tag.
        assert b'<h1>Unauthorized Access</h1>' in home_response.data

    def test_add_wish_redirects_unauthorized_user(self, client):
        """Ensures an unauthenticated user is redirected when trying to add a wish."""
        response = client.post('/addWish', data={
            'inputTitle': 'Unauthorized Wish',
            'inputDescription': 'This should fail.'
        }, follow_redirects=False)
        
        assert response.status_code == 302
        # Assert that the redirect goes to the sign-in page.
        assert '/showSignIn' in response.headers['Location']

# -----------------------------------------------------------------------------
# Test Suite for Wishlist (Authenticated User)
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
        # FIX: Check for the "Add Wish" link, which is unique to userHome.html
        assert b'<a href="/showAddWish">Add Wish</a>' in response.data

    def test_add_wish_succeeds_and_redirects(self, client_with_login):
        """Tests that creating a new wish correctly redirects the user."""
        response = client_with_login.post('/addWish', data={'inputTitle': 'Learn Pytest', 'inputDescription': 'Master fixtures.'})
        assert response.status_code == 302
        assert response.headers['Location'] == '/userHome'

    def test_get_wish_api_returns_correct_json_data(self, client_with_login):
        """Verifies the /getWish API returns wishes in JSON format."""
        client_with_login.post('/addWish', data={'inputTitle': 'Test API', 'inputDescription': 'Check JSON response.'})
        response = client_with_login.get('/getWish')
        assert response.status_code == 200
        wishes = response.get_json()
        assert isinstance(wishes, list)
        assert any(wish['Title'] == 'Test API' for wish in wishes)