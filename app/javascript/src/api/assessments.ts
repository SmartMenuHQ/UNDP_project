// Assessment API functions

interface CreateAssessmentRequest {
	title: string;
	description: string;
	active: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
}

interface Assessment {
	id: number;
	title: string;
	description: string;
	active: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
	sections_count: number;
	questions_count: number;
	created_at: string;
	updated_at: string;
}

interface ApiResponse<T> {
	status: 'ok' | 'error' | 'redirect';
	data: T;
	errors: string[];
	notes: string[];
}

// Get auth token from localStorage
const getAuthToken = (): string | null => {
	return localStorage.getItem('auth_token');
};

// Handle authentication errors
const handleAuthError = (response: Response) => {
	if (response.status === 401) {
		// Clear invalid auth data
		localStorage.removeItem('auth_token');
		localStorage.removeItem('auth_user');
		// Redirect to login
		window.location.href = '/app/login';
		throw new Error('Authentication required. Please log in again.');
	}
};

// Create new assessment
export const createAssessment = async (assessmentData: CreateAssessmentRequest): Promise<Assessment> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch('/api/v1/admin/assessments', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${token}`,
		},
		body: JSON.stringify(assessmentData),
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to create assessment'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result: ApiResponse<Assessment> = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to create assessment');
	}

	return result.data;
};

// Fetch all assessments
export const fetchAssessments = async (): Promise<Assessment[]> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch('/api/v1/admin/assessments', {
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		throw new Error(`HTTP Error: ${response.status}`);
	}

	const result: ApiResponse<{assessments: Assessment[], total_count: number, active_count: number, inactive_count: number}> = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to fetch assessments');
	}

	return result.data.assessments;
};

// Fetch single assessment
export const fetchAssessment = async (id: number): Promise<Assessment> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${id}`, {
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		throw new Error(`HTTP Error: ${response.status}`);
	}

	const result: ApiResponse<Assessment> = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to fetch assessment');
	}

	return result.data;
};