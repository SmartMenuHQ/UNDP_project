"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useNavigate } from 'react-router';

interface User {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  full_name: string;
  display_name: string;
  admin: boolean;
  profile_completed: boolean;
  default_language: string;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  checkAuth: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = !!user && !!token;

  // Initialize auth state from localStorage
  useEffect(() => {
    const storedToken = localStorage.getItem('auth_token');
    const storedUser = localStorage.getItem('auth_user');

    if (storedToken && storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        setToken(storedToken);
        setUser(parsedUser);
        // Validate token by making a request to /me endpoint
        validateToken(storedToken);
      } catch (error) {
        console.error('Error parsing stored user data:', error);
        clearAuthData();
      }
    } else {
      setIsLoading(false);
    }
  }, []);

  const validateToken = async (authToken: string) => {
    try {
      const response = await fetch('/api/v1/auth/me', {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const result = await response.json();
        if (result.status === 'ok' && result.data) {
          setUser(result.data);
          setToken(authToken);
        } else {
          clearAuthData();
        }
      } else {
        clearAuthData();
      }
    } catch (error) {
      console.error('Token validation failed:', error);
      clearAuthData();
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string): Promise<void> => {
    setIsLoading(true);
    try {
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          auth: {
            email_address: email,
            password: password,
          }
        }),
      });

      const result = await response.json().catch(() => ({ 
        status: 'error', 
        errors: ['Unable to process login request'] 
      }));

      if (!response.ok) {
        // Handle HTTP errors with proper error message extraction
        let errorMessage = 'Login failed';
        
        if (result.errors && Array.isArray(result.errors) && result.errors.length > 0) {
          const firstError = result.errors[0];
          // Extract message from error object structure
          if (typeof firstError === 'string') {
            errorMessage = firstError;
          } else if (firstError && typeof firstError === 'object' && firstError.message) {
            errorMessage = firstError.message;
          } else {
            errorMessage = 'Login failed';
          }
        } else if (result.error) {
          errorMessage = typeof result.error === 'string' ? result.error : 'Login failed';
        } else if (response.status === 401) {
          errorMessage = 'Invalid email or password';
        } else if (response.status >= 500) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = `Login failed (${response.status})`;
        }
        
        throw new Error(errorMessage);
      }
      
      if (result.status === 'error') {
        let errorMessage = 'Login failed';
        
        if (result.errors && Array.isArray(result.errors) && result.errors.length > 0) {
          const firstError = result.errors[0];
          // Extract message from error object structure
          if (typeof firstError === 'string') {
            errorMessage = firstError;
          } else if (firstError && typeof firstError === 'object' && firstError.message) {
            errorMessage = firstError.message;
          } else {
            errorMessage = 'Login failed';
          }
        } else if (result.error) {
          errorMessage = typeof result.error === 'string' ? result.error : 'Login failed';
        }
        
        throw new Error(errorMessage);
      }

      if (result.data && result.data.session && result.data.user) {
        const { session, user: userData } = result.data;
        const authToken = session.token;
        
        // Store in localStorage
        localStorage.setItem('auth_token', authToken);
        localStorage.setItem('auth_user', JSON.stringify(userData));
        
        // Update state
        setToken(authToken);
        setUser(userData);
      } else {
        throw new Error('Invalid response format');
      }
    } catch (error) {
      console.error('Login error:', error);
      clearAuthData();
      // Re-throw the error with proper message handling
      if (error instanceof Error) {
        throw error;
      } else {
        // Handle case where error might be an object or other type
        throw new Error('An unexpected error occurred during login');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    clearAuthData();
    // Optional: Call logout endpoint to invalidate token on server
    if (token) {
      fetch('/api/v1/auth/logout', {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }).catch(console.error);
    }
  };

  const checkAuth = async (): Promise<void> => {
    if (token) {
      await validateToken(token);
    }
  };

  const clearAuthData = () => {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_user');
    setToken(null);
    setUser(null);
  };

  const value: AuthContextType = {
    user,
    token,
    isLoading,
    isAuthenticated,
    login,
    logout,
    checkAuth,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};