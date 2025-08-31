// Conditional logic evaluation utilities

export interface QuestionResponse {
	questionId: number;
	selectedOptionIds?: number[];
	textValue?: string;
	numberValue?: number;
	booleanValue?: boolean;
	dateValue?: string;
}

export interface ConditionalRule {
	trigger_question_id: number;
	trigger_response_type: string;
	trigger_values: any[];
	operator: string;
}

export interface Question {
	id: number;
	text: string;
	type: string;
	order: number;
	is_conditional?: boolean;
	is_required: boolean;
	options?: Array<{ id: number; text: string }>;
	meta_data?: any;
	// Conditional logic fields - these might be nested in visibility_conditions
	trigger_question_id?: number;
	trigger_response_type?: string;
	trigger_values?: any[];
	operator?: string;
	visibility_conditions?: any;
}

export interface Section {
	id: number;
	name: string;
	order: number;
	questions: Question[];
	is_conditional?: boolean;
	trigger_question_id?: number;
	trigger_response_type?: string;
	trigger_values?: any[];
	operator?: string;
	visibility_conditions?: any;
}

/**
 * Extract conditional rule from a question or section
 */
export const getConditionalRule = (item: Question | Section): ConditionalRule | null => {
	if (!item.is_conditional) return null;

	// Try to get from direct properties first
	if (item.trigger_question_id) {
		return {
			trigger_question_id: item.trigger_question_id,
			trigger_response_type: item.trigger_response_type || 'equals',
			trigger_values: item.trigger_values || [],
			operator: item.operator || 'equals'
		};
	}

	// Try to get from visibility_conditions object
	if (item.visibility_conditions) {
		const conditions = item.visibility_conditions;
		return {
			trigger_question_id: conditions.trigger_question_id,
			trigger_response_type: conditions.trigger_response_type || 'equals',
			trigger_values: conditions.trigger_values || [],
			operator: conditions.operator || 'equals'
		};
	}

	return null;
};

/**
 * Evaluate if a question should be visible based on responses
 */
export const isQuestionVisible = (
	question: Question,
	responses: Map<number, QuestionResponse>
): boolean => {
	const rule = getConditionalRule(question);
	if (!rule) return true; // Not conditional, always visible

	const triggerResponse = responses.get(rule.trigger_question_id);
	if (!triggerResponse) return false; // Trigger question not answered yet

	return evaluateCondition(rule, triggerResponse);
};

/**
 * Evaluate if a section should be visible based on responses
 */
export const isSectionVisible = (
	section: Section,
	responses: Map<number, QuestionResponse>
): boolean => {
	const rule = getConditionalRule(section);
	if (!rule) return true; // Not conditional, always visible

	const triggerResponse = responses.get(rule.trigger_question_id);
	if (!triggerResponse) return false; // Trigger question not answered yet

	return evaluateCondition(rule, triggerResponse);
};

/**
 * Core condition evaluation logic
 */
export const evaluateCondition = (rule: ConditionalRule, response: QuestionResponse): boolean => {
	const { trigger_response_type, trigger_values, operator } = rule;

	switch (trigger_response_type) {
		case 'option_selected':
			return evaluateOptionCondition(trigger_values, response.selectedOptionIds || [], operator);
		
		case 'value_equals':
		case 'text_equals':
			return evaluateTextCondition(trigger_values, response.textValue || '', operator);
		
		case 'value_range':
		case 'number_equals':
			return evaluateNumberCondition(trigger_values, response.numberValue || 0, operator);
		
		case 'boolean_equals':
			return evaluateBooleanCondition(trigger_values, response.booleanValue || false, operator);
		
		default:
			// Default to text comparison
			const responseValue = response.textValue || response.numberValue?.toString() || '';
			return evaluateTextCondition(trigger_values, responseValue, operator);
	}
};

/**
 * Evaluate option-based conditions (multiple choice, radio)
 */
export const evaluateOptionCondition = (
	triggerValues: any[],
	selectedOptions: number[],
	operator: string
): boolean => {
	const triggerOptionIds = triggerValues.map(v => parseInt(v.toString()));
	const selectedOptionIds = selectedOptions.map(v => parseInt(v.toString()));

	switch (operator) {
		case 'contains':
		case 'any':
			return triggerOptionIds.some(id => selectedOptionIds.includes(id));
		
		case 'equals':
		case 'exact':
			return JSON.stringify(selectedOptionIds.sort()) === JSON.stringify(triggerOptionIds.sort());
		
		case 'not_equals':
			return JSON.stringify(selectedOptionIds.sort()) !== JSON.stringify(triggerOptionIds.sort());
		
		case 'all':
			return triggerOptionIds.every(id => selectedOptionIds.includes(id));
		
		case 'none':
			return !triggerOptionIds.some(id => selectedOptionIds.includes(id));
		
		default:
			return triggerOptionIds.some(id => selectedOptionIds.includes(id));
	}
};

/**
 * Evaluate text-based conditions
 */
export const evaluateTextCondition = (
	triggerValues: any[],
	responseText: string,
	operator: string
): boolean => {
	const responseValue = responseText.toLowerCase().trim();
	const triggerTexts = triggerValues.map(v => v.toString().toLowerCase().trim());

	switch (operator) {
		case 'equals':
			return triggerTexts.includes(responseValue);
		
		case 'not_equals':
			return !triggerTexts.includes(responseValue);
		
		case 'contains':
			return triggerTexts.some(text => responseValue.includes(text));
		
		case 'not_contains':
			return !triggerTexts.some(text => responseValue.includes(text));
		
		case 'starts_with':
			return triggerTexts.some(text => responseValue.startsWith(text));
		
		case 'ends_with':
			return triggerTexts.some(text => responseValue.endsWith(text));
		
		default:
			return triggerTexts.includes(responseValue);
	}
};

/**
 * Evaluate number-based conditions
 */
export const evaluateNumberCondition = (
	triggerValues: any[],
	responseNumber: number,
	operator: string
): boolean => {
	const triggerNumbers = triggerValues.map(v => parseFloat(v.toString())).filter(n => !isNaN(n));
	
	if (triggerNumbers.length === 0) return false;

	switch (operator) {
		case 'equals':
			return triggerNumbers.includes(responseNumber);
		
		case 'not_equals':
			return !triggerNumbers.includes(responseNumber);
		
		case 'greater_than':
			return responseNumber > triggerNumbers[0];
		
		case 'less_than':
			return responseNumber < triggerNumbers[0];
		
		case 'greater_than_or_equal':
			return responseNumber >= triggerNumbers[0];
		
		case 'less_than_or_equal':
			return responseNumber <= triggerNumbers[0];
		
		case 'between':
		case 'range':
			if (triggerNumbers.length >= 2) {
				const min = Math.min(...triggerNumbers);
				const max = Math.max(...triggerNumbers);
				return responseNumber >= min && responseNumber <= max;
			}
			return false;
		
		default:
			return triggerNumbers.includes(responseNumber);
	}
};

/**
 * Evaluate boolean-based conditions
 */
export const evaluateBooleanCondition = (
	triggerValues: any[],
	responseBoolean: boolean,
	operator: string
): boolean => {
	if (triggerValues.length === 0) return false;
	
	const triggerBoolean = triggerValues[0].toString().toLowerCase() === 'true';
	
	switch (operator) {
		case 'equals':
			return responseBoolean === triggerBoolean;
		
		case 'not_equals':
			return responseBoolean !== triggerBoolean;
		
		default:
			return responseBoolean === triggerBoolean;
	}
};

/**
 * Get all visible questions from sections based on current responses
 */
export const getVisibleQuestions = (
	sections: Section[],
	responses: Map<number, QuestionResponse>
): Question[] => {
	const visibleQuestions: Question[] = [];
	
	for (const section of sections) {
		// Check if section is visible
		if (!isSectionVisible(section, responses)) continue;
		
		// Get visible questions from this section
		for (const question of section.questions) {
			if (isQuestionVisible(question, responses)) {
				visibleQuestions.push(question);
			}
		}
	}
	
	return visibleQuestions.sort((a, b) => a.order - b.order);
};

/**
 * Get all visible sections based on current responses
 */
export const getVisibleSections = (
	sections: Section[],
	responses: Map<number, QuestionResponse>
): Section[] => {
	return sections
		.filter(section => isSectionVisible(section, responses))
		.map(section => ({
			...section,
			questions: section.questions.filter(question => isQuestionVisible(question, responses))
		}))
		.sort((a, b) => a.order - b.order);
};

/**
 * Simulate a response for testing conditional logic
 */
export const createTestResponse = (
	questionId: number,
	type: 'option' | 'text' | 'number' | 'boolean',
	value: any
): QuestionResponse => {
	const response: QuestionResponse = { questionId };
	
	switch (type) {
		case 'option':
			response.selectedOptionIds = Array.isArray(value) ? value : [value];
			break;
		case 'text':
			response.textValue = value.toString();
			break;
		case 'number':
			response.numberValue = parseFloat(value);
			break;
		case 'boolean':
			response.booleanValue = Boolean(value);
			break;
	}
	
	return response;
};