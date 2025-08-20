import pytest
from ..app import app

# -----------------------------------------------------------------------------
# Core Test Fixtures
# -----------------------------------------------------------------------------

@pytest.fixture
def client():
    """
    Creates and configures a test client for each test function.
    This fixture ensures a clean, isolated application context for every test case.
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
    """Asserts that the main landing page loads correctly and returns a 200 OK status."""
    response = client.get('/')
    assert response.status_code == 200
    assert b"Welcome To The BucketList App" in response.data

def test_signup_page_renders_successfully(client):
    """Asserts that the user registration page loads correctly."""
    response = client.get('/showSignUp')
    assert response.status_code == 200
    assert b"Sign Up" in response.data

def test_signin_page_renders_successfully(client):
    """Asserts that the user login page loads correctly."""
    response = client.get('/showSignIn')
    assert response.status_code == 200
    assert b"Sign In" in response.data

# -----------------------------------------------------------------------------
# Test Suite for User Authentication Workflows
# -----------------------------------------------------------------------------
class TestAuthentication:
    """Groups all tests related to user sign-up, login, and logout."""

    def test_user_signup_succeeds_with_valid_data(self, client):
        """Verifies that a new user can be created successfully via the signUp endpoint."""
        response = client.post('/signUp', data={
            'inputName': 'New User',
            'inputEmail': 'new.user@example.com',
            'inputPassword': 'securepassword'
        })
        
        assert response.status_code == 200
        json_response = response.get_json()
        assert json_response.get('message') == 'User created successfully !'

    def test_signup_fails_if_user_already_exists(self, client):
        """Ensures the system prevents registration of a user with a duplicate email."""
        # Arrange: Create the initial user
        client.post('/signUp', data={
            'inputName': 'Existing User',
            'inputEmail': 'existing@example.com',
            'inputPassword': 'password'
        })
        
        # Act: Attempt to create the same user again
        response = client.post('/signUp', data={
            'inputName': 'Another Name',
            'inputEmail': 'existing@example.com',
            'inputPassword': 'password'
        })
        
        # Assert: Expect an error message from the backend
        assert response.status_code == 200
        json_response = response.get_json()
        assert 'error' in json_response
        assert 'Username Exists' in json_response['error']
        
    def test_signup_fails_with_missing_required_fields(self, client):
        """Verifies that the endpoint returns an error for incomplete form submissions."""
        response = client.post('/signUp', data={
            'inputName': 'Incomplete User',
            'inputEmail': '',  # Missing email
            'inputPassword': 'password'
        })
        
        assert response.status_code == 200
        json_response = response.get_json()
        assert 'html' in json_response
        assert 'Enter the required fields' in json_response['html']

    def test_login_succeeds_and_redirects_with_correct_credentials(self, client):
        """Tests the complete login flow: valid credentials should result in a redirect to the user's home."""
        # Arrange: A user must exist to be able to log in
        client.post('/signUp', data={
            'inputName': 'Login User',
            'inputEmail': 'login.user@example.com',
            'inputPassword': 'loginpass'
        })
        
        # Act: Attempt to log in
        response = client.post('/validateLogin', data={
            'inputEmail': 'login.user@example.com',
            'inputPassword': 'loginpass'
        }, follow_redirects=False) # Disable auto-redirect to inspect the 302 response
        
        # Assert: A successful login should issue a redirect (status 302)
        assert response.status_code == 302
        assert response.headers['Location'] == '/userHome'

    def test_login_fails_with_incorrect_password(self, client):
        """Ensures that login attempts with a valid email but incorrect password are rejected."""
        client.post('/signUp', data={
            'inputName': 'Wrong Pass User',
            'inputEmail': 'wrong.pass@example.com',
            'inputPassword': 'correct_password'
        })
        
        response = client.post('/validateLogin', data={
            'inputEmail': 'wrong.pass@example.com',
            'inputPassword': 'incorrect_password'
        })
        
        assert response.status_code == 200
        assert b'Wrong Email address or Password' in response.data

    def test_login_fails_with_nonexistent_user(self, client):
        """Ensures that login attempts for users not in the database are rejected."""
        response = client.post('/validateLogin', data={
            'inputEmail': 'nobody@example.com',
            'inputPassword': 'any_password'
        })
        
        assert response.status_code == 200
        assert b'Wrong Email address or Password' in response.data

    def test_logout_clears_session_and_redirects_to_main_page(self, client):
        """Verifies that the logout endpoint correctly terminates the session and redirects."""
        # Arrange: Log in a user to establish a session
        client.post('/signUp', data={'inputName': 'Logout User', 'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        client.post('/validateLogin', data={'inputEmail': 'logout@example.com', 'inputPassword': 'pass'})
        
        # Act: Hit the logout endpoint
        response = client.get('/logout', follow_redirects=True)
        
        # Assert: User is redirected to the main page and session is cleared
        assert response.status_code == 200
        assert b"Welcome To The BucketList App" in response.data
        
        # Further assert that protected routes are no longer accessible
        home_response = client.get('/userHome')
        assert b'Unauthorized Access' in home_response.data

# -----------------------------------------------------------------------------
# Test Suite for Wishlist (CRUD) Functionality
# -----------------------------------------------------------------------------
class TestWishes:
    """Groups tests for all wishlist-related endpoints, which require an authenticated user."""

    @pytest.fixture(autouse=True)
    def client_with_login(self, client):
        """
        An auto-use fixture that logs in a user before each test in this class.
        This ensures a consistent, authenticated state for testing protected endpoints.
        """
        client.post('/signUp', data={'inputName': 'Wish User', 'inputEmail': 'wish@example.com', 'inputPassword': 'wishpass'})
        client.post('/validateLogin', data={'inputEmail': 'wish@example.com', 'inputPassword': 'wishpass'})
        yield client

    def test_user_home_is_accessible_when_logged_in(self, client_with_login):
        """Verifies that an authenticated user can access their home page."""
        response = client_with_login.get('/userHome')
        assert response.status_code == 200
        assert b"My Bucket List" in response.data

    def test_add_wish_succeeds_for_authenticated_user(self, client_with_login):
        """Tests the successful creation of a new wish item."""
        response = client_with_login.post('/addWish', data={
            'inputTitle': 'Learn Advanced Pytest',
            'inputDescription': 'Master fixtures and plugins.'
        }, follow_redirects=True)
        
        assert response.status_code == 200
        # Assert that the new wish appears on the page after creation
        assert b"Learn Advanced Pytest" in response.data

    def test_get_wish_api_returns_correct_json_data(self, client_with_login):
        """Verifies the /getWish API endpoint returns a list of wishes in JSON format."""
        # Arrange: Create a wish to be retrieved
        client_with_login.post('/addWish', data={
            'inputTitle': 'Test API Endpoint',
            'inputDescription': 'Ensure the API endpoint works as expected.'
        })
        
        # Act: Call the API endpoint
        response = client_with_login.get('/getWish')
        
        # Assert: Check the response structure and content
        assert response.status_code == 200
        wishes = response.get_json()
        assert isinstance(wishes, list)
        assert len(wishes) == 1
        assert wishes[0]['Title'] == 'Test API Endpoint'
        assert all(key in wishes[0] for key in ['Id', 'Description', 'Date'])

    def test_add_wish_fails_for_unauthorized_user(self, client):
        """
        Ensures that an unauthenticated user cannot add a wish.
        Note: This test uses the standard `client` fixture, not `client_with_login`.
        """
        response = client.post('/addWish', data={
            'inputTitle': 'Attempt to add wish without login',
            'inputDescription': 'This should be rejected.'
        })
        assert response.status_code == 200
        assert b'Unauthorized Access' in response.data