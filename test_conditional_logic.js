// Simple test to verify conditional logic evaluation
// This can be run in the browser console to test the logic

// Sample test data
const testSections = [
	{
		id: 1,
		name: "Section 1",
		order: 1,
		questions: [
			{
				id: 1,
				text: "What is your age?",
				type: "AssessmentQuestions::RangeType",
				order: 1,
				is_required: true,
				is_conditional: false
			},
			{
				id: 2,
				text: "Are you over 18?",
				type: "AssessmentQuestions::BooleanType", 
				order: 2,
				is_required: true,
				is_conditional: false
			},
			{
				id: 3,
				text: "What is your favorite color?",
				type: "AssessmentQuestions::MultipleChoice",
				order: 3,
				is_required: false,
				is_conditional: true,
				trigger_question_id: 1,
				trigger_response_type: "value_range",
				trigger_values: [18],
				operator: "greater_than",
				options: [
					{ id: 1, text: "Red" },
					{ id: 2, text: "Blue" },
					{ id: 3, text: "Green" }
				]
			},
			{
				id: 4,
				text: "Which school do you attend?",
				type: "AssessmentQuestions::MultipleChoice",
				order: 4,
				is_required: false,
				is_conditional: true,
				trigger_question_id: 1,
				trigger_response_type: "value_range", 
				trigger_values: [18],
				operator: "less_than",
				options: [
					{ id: 4, text: "Elementary" },
					{ id: 5, text: "Middle School" },
					{ id: 6, text: "High School" }
				]
			},
			{
				id: 5,
				text: "What color did you choose?",
				type: "AssessmentQuestions::RichText",
				order: 5,
				is_required: false,
				is_conditional: true,
				trigger_question_id: 3,
				trigger_response_type: "option_selected",
				trigger_values: [1], // Red option
				operator: "contains"
			}
		]
	}
];

// Test cases
const testCases = [
	{
		name: "Age 15 - should show school question, hide color question",
		responses: new Map([
			[1, { questionId: 1, numberValue: 15 }]
		]),
		expectedVisible: [1, 2, 4] // age, over 18, school
	},
	{
		name: "Age 25 - should show color question, hide school question", 
		responses: new Map([
			[1, { questionId: 1, numberValue: 25 }]
		]),
		expectedVisible: [1, 2, 3] // age, over 18, color
	},
	{
		name: "Age 25 + Red color - should show follow-up text question",
		responses: new Map([
			[1, { questionId: 1, numberValue: 25 }],
			[3, { questionId: 3, selectedOptionIds: [1] }] // Red
		]),
		expectedVisible: [1, 2, 3, 5] // age, over 18, color, follow-up
	},
	{
		name: "Age 25 + Blue color - should not show follow-up text question",
		responses: new Map([
			[1, { questionId: 1, numberValue: 25 }],
			[3, { questionId: 3, selectedOptionIds: [2] }] // Blue
		]),
		expectedVisible: [1, 2, 3] // age, over 18, color (no follow-up)
	}
];

console.log("Testing Conditional Logic...\n");

// Import the logic (this would be from the actual module)
// For testing, we'll inline the key functions:

const getConditionalRule = (item) => {
	if (!item.is_conditional) return null;
	
	return {
		trigger_question_id: item.trigger_question_id,
		trigger_response_type: item.trigger_response_type || 'equals',
		trigger_values: item.trigger_values || [],
		operator: item.operator || 'equals'
	};
};

const evaluateCondition = (rule, response) => {
	const { trigger_response_type, trigger_values, operator } = rule;

	switch (trigger_response_type) {
		case 'option_selected':
			return evaluateOptionCondition(trigger_values, response.selectedOptionIds || [], operator);
		
		case 'value_range':
		case 'number_equals':
			return evaluateNumberCondition(trigger_values, response.numberValue || 0, operator);
		
		default:
			return false;
	}
};

const evaluateOptionCondition = (triggerValues, selectedOptions, operator) => {
	const triggerOptionIds = triggerValues.map(v => parseInt(v.toString()));
	const selectedOptionIds = selectedOptions.map(v => parseInt(v.toString()));

	switch (operator) {
		case 'contains':
		case 'any':
			return triggerOptionIds.some(id => selectedOptionIds.includes(id));
		default:
			return triggerOptionIds.some(id => selectedOptionIds.includes(id));
	}
};

const evaluateNumberCondition = (triggerValues, responseNumber, operator) => {
	const triggerNumbers = triggerValues.map(v => parseFloat(v.toString())).filter(n => !isNaN(n));
	
	if (triggerNumbers.length === 0) return false;

	switch (operator) {
		case 'greater_than':
			return responseNumber > triggerNumbers[0];
		case 'less_than':
			return responseNumber < triggerNumbers[0];
		default:
			return false;
	}
};

const isQuestionVisible = (question, responses) => {
	const rule = getConditionalRule(question);
	if (!rule) return true;

	const triggerResponse = responses.get(rule.trigger_question_id);
	if (!triggerResponse) return false;

	return evaluateCondition(rule, triggerResponse);
};

const getVisibleQuestions = (sections, responses) => {
	const visibleQuestions = [];
	
	for (const section of sections) {
		for (const question of section.questions) {
			if (isQuestionVisible(question, responses)) {
				visibleQuestions.push(question.id);
			}
		}
	}
	
	return visibleQuestions.sort();
};

// Run tests
testCases.forEach((testCase, index) => {
	console.log(`Test ${index + 1}: ${testCase.name}`);
	
	const actualVisible = getVisibleQuestions(testSections, testCase.responses);
	const expectedVisible = testCase.expectedVisible.sort();
	
	const passed = JSON.stringify(actualVisible) === JSON.stringify(expectedVisible);
	
	console.log(`  Expected: [${expectedVisible.join(', ')}]`);
	console.log(`  Actual:   [${actualVisible.join(', ')}]`);
	console.log(`  Result:   ${passed ? '✅ PASS' : '❌ FAIL'}\n`);
	
	if (!passed) {
		console.log("  Detailed analysis:");
		expectedVisible.forEach(qId => {
			if (!actualVisible.includes(qId)) {
				const question = testSections[0].questions.find(q => q.id === qId);
				console.log(`    Missing question ${qId}: "${question?.text}"`);
			}
		});
		actualVisible.forEach(qId => {
			if (!expectedVisible.includes(qId)) {
				const question = testSections[0].questions.find(q => q.id === qId);
				console.log(`    Unexpected question ${qId}: "${question?.text}"`);
			}
		});
		console.log();
	}
});

console.log("Testing completed!");