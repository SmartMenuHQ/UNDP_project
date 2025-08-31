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

// Create new section
export const createAssessmentSection = async (assessmentId: number, sectionData: { name: string; order?: number }): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${token}`,
		},
		body: JSON.stringify({ section: sectionData }),
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to create section'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to create section');
	}

	return result.data;
};

// Fetch assessment sections
export const fetchAssessmentSections = async (assessmentId: number): Promise<any[]> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections`, {
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		throw new Error(`HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to fetch sections');
	}

	return result.data.sections;
};

// Delete section
export const deleteAssessmentSection = async (assessmentId: number, sectionId: number): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections/${sectionId}`, {
		method: 'DELETE',
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to delete section'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to delete section');
	}

	return result.data;
};

// Create new question
export const createAssessmentQuestion = async (assessmentId: number, sectionId: number, questionData: any): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections/${sectionId}/questions`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${token}`,
		},
		body: JSON.stringify({ question: questionData }),
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to create question'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to create question');
	}

	return result.data;
};

// Update question
export const updateAssessmentQuestion = async (assessmentId: number, sectionId: number, questionId: number, questionData: any): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections/${sectionId}/questions/${questionId}`, {
		method: 'PATCH',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${token}`,
		},
		body: JSON.stringify({ question: questionData }),
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to update question'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to update question');
	}

	return result.data;
};

// Delete question
export const deleteAssessmentQuestion = async (assessmentId: number, sectionId: number, questionId: number): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/admin/assessments/${assessmentId}/sections/${sectionId}/questions/${questionId}`, {
		method: 'DELETE',
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to delete question'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to delete question');
	}

	return result.data;
};
// Update question option
export const updateQuestionOption = async (questionId: number, optionId: number, optionData: any): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error("Authentication required");
	}

	const response = await fetch(`/api/v1/admin/questions/${questionId}/options/${optionId}`, {
		method: "PATCH",
		headers: {
			"Content-Type": "application/json",
			"Authorization": `Bearer ${token}`,
		},
		body: JSON.stringify({ option: optionData }),
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ["Failed to update option"] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === "error") {
		throw new Error(result.errors[0] || "Failed to update option");
	}

	return result.data;
};

// User-facing assessment API functions for preview

// Fetch assessment for user preview (non-admin)
export const fetchAssessmentForPreview = async (id: number): Promise<any> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/assessments/${id}`, {
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to fetch assessment'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to fetch assessment');
	}

	return result.data;
};

// Fetch assessment sections for user preview
export const fetchAssessmentSectionsForPreview = async (assessmentId: number): Promise<any[]> => {
	const token = getAuthToken();
	
	if (!token) {
		throw new Error('Authentication required');
	}

	const response = await fetch(`/api/v1/assessments/${assessmentId}/sections`, {
		headers: {
			'Authorization': `Bearer ${token}`,
			'Content-Type': 'application/json',
		},
	});

	if (!response.ok) {
		handleAuthError(response);
		const errorData = await response.json().catch(() => ({ errors: ['Failed to fetch sections'] }));
		throw new Error(errorData.errors?.[0] || `HTTP Error: ${response.status}`);
	}

	const result = await response.json();
	
	if (result.status === 'error') {
		throw new Error(result.errors[0] || 'Failed to fetch sections');
	}

	return result.data.sections || [];
};
