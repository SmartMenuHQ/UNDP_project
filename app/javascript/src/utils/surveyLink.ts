// Survey link encoding/decoding utilities

// Secret key for assessment ID obfuscation (in production, this would be from env vars)
const SECRET_KEY = 'undp_survey_secret_2024';

/**
 * Encode assessment ID using btoa with secret key and timestamp
 * @param assessmentId The assessment ID to encode
 * @returns URL-safe base64 encoded string
 */
export const encodeAssessmentId = (assessmentId: number): string => {
	try {
		// Combine assessment ID with secret and timestamp for additional security
		const timestamp = Math.floor(Date.now() / 1000 / 3600); // Changes every hour
		const payload = `${SECRET_KEY}_${assessmentId}_${timestamp}`;
		
		// Base64 encode the payload
		const encoded = btoa(payload);
		
		// Make it URL-safe by replacing problematic characters
		const urlSafe = encoded
			.replace(/\+/g, '-')
			.replace(/\//g, '_')
			.replace(/=/g, '');
			
		return urlSafe;
	} catch (error) {
		console.error('Error encoding assessment ID:', error);
		// Fallback to simple encoding if btoa fails
		return btoa(assessmentId.toString()).replace(/=/g, '');
	}
};

/**
 * Decode assessment ID using atob with secret validation
 * @param hashedId The encoded assessment ID
 * @returns Decoded assessment ID or null if invalid
 */
export const decodeAssessmentId = (hashedId: string): number | null => {
	try {
		// Convert back from URL-safe format
		let encoded = hashedId
			.replace(/-/g, '+')
			.replace(/_/g, '/');
		
		// Add padding if needed
		while (encoded.length % 4) {
			encoded += '=';
		}
		
		// Decode from base64
		const decoded = atob(encoded);
		
		// Extract parts
		const parts = decoded.split('_');
		if (parts.length !== 3 || parts[0] !== SECRET_KEY) {
			return null; // Invalid format or wrong secret
		}
		
		const assessmentId = parseInt(parts[1], 10);
		const timestamp = parseInt(parts[2], 10);
		
		// Validate timestamp (allow 24 hour window)
		const currentTimestamp = Math.floor(Date.now() / 1000 / 3600);
		if (Math.abs(currentTimestamp - timestamp) > 24) {
			console.warn('Survey link expired');
			// Still return the ID but could be used to show expiry warning
		}
		
		return isNaN(assessmentId) ? null : assessmentId;
	} catch (error) {
		console.error('Error decoding assessment ID:', error);
		return null;
	}
};

/**
 * Generate a complete survey URL for sharing
 * @param assessmentId The assessment ID to create a survey link for
 * @param baseUrl Optional base URL (defaults to current origin)
 * @returns Complete survey URL
 */
export const generateSurveyUrl = (assessmentId: number, baseUrl?: string): string => {
	const hashedId = encodeAssessmentId(assessmentId);
	const host = baseUrl || window.location.origin;
	return `${host}/app/survey/${hashedId}`;
};

/**
 * Validate if a survey link is still valid (within time window)
 * @param hashedId The encoded assessment ID
 * @returns Object with validity status and assessment ID
 */
export const validateSurveyLink = (hashedId: string): { valid: boolean; assessmentId: number | null; expired: boolean } => {
	try {
		// Convert back from URL-safe format
		let encoded = hashedId
			.replace(/-/g, '+')
			.replace(/_/g, '/');
		
		// Add padding if needed
		while (encoded.length % 4) {
			encoded += '=';
		}
		
		// Decode from base64
		const decoded = atob(encoded);
		
		// Extract parts
		const parts = decoded.split('_');
		if (parts.length !== 3 || parts[0] !== SECRET_KEY) {
			return { valid: false, assessmentId: null, expired: false };
		}
		
		const assessmentId = parseInt(parts[1], 10);
		const timestamp = parseInt(parts[2], 10);
		
		if (isNaN(assessmentId)) {
			return { valid: false, assessmentId: null, expired: false };
		}
		
		// Check timestamp (allow 24 hour window)
		const currentTimestamp = Math.floor(Date.now() / 1000 / 3600);
		const expired = Math.abs(currentTimestamp - timestamp) > 24;
		
		return {
			valid: true,
			assessmentId,
			expired
		};
	} catch (error) {
		console.error('Error validating survey link:', error);
		return { valid: false, assessmentId: null, expired: false };
	}
};