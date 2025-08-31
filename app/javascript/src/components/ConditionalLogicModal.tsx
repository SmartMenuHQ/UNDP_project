"use client";

import React, { useState, useEffect } from 'react';
import { Card } from 'flowbite-react';
import { X, AlertCircle, CheckCircle } from 'lucide-react';

interface AssessmentQuestion {
	id: number;
	text: string;
	type: string;
	question_type_name: string;
	sub_type: string;
	order: number;
	is_required: boolean;
	active: boolean;
	is_conditional?: boolean;
	options: any[];
	meta_data?: any;
}

interface AssessmentSection {
	id: number;
	name: string;
	order: number;
	questions: AssessmentQuestion[];
}

interface ConditionalLogicModalProps {
	show: boolean;
	onClose: () => void;
	sections: AssessmentSection[];
	questionId?: number;
	sectionId?: number;
	onSave: (data: ConditionalLogicData) => void;
}

interface ConditionalLogicData {
	is_conditional: boolean;
	trigger_question_id?: number;
	trigger_response_type?: string;
	trigger_values?: any[];
	operator?: string;
}

const ConditionalLogicModal: React.FC<ConditionalLogicModalProps> = ({
	show,
	onClose,
	sections,
	questionId,
	sectionId,
	onSave
}) => {
	const [isEnabled, setIsEnabled] = useState(false);
	const [selectedTriggerQuestion, setSelectedTriggerQuestion] = useState<number | null>(null);
	const [triggerResponseType, setTriggerResponseType] = useState('equals');
	const [triggerValues, setTriggerValues] = useState<string>('');
	const [operator, setOperator] = useState('equals');
	const [selectedTriggerQuestionData, setSelectedTriggerQuestionData] = useState<AssessmentQuestion | null>(null);
	const [availableOptions, setAvailableOptions] = useState<any[]>([]);

	// Get current question data
	const currentQuestion = sections
		.find(s => s.id === sectionId)
		?.questions.find(q => q.id === questionId);

	// Get all previous questions
	const previousQuestions = sections.flatMap(section =>
		section.questions
			.filter(q => q.order < (currentQuestion?.order || 999))
			.map(q => ({ ...q, sectionName: section.name }))
	);

	// Initialize form with existing data
	useEffect(() => {
		if (currentQuestion) {
			setIsEnabled(currentQuestion.is_conditional || false);
			// Add more initialization if we have existing conditional data
		}
	}, [currentQuestion]);

	// Update available options when trigger question changes
	useEffect(() => {
		if (selectedTriggerQuestion) {
			const triggerQuestion = sections.flatMap(s => s.questions)
				.find(q => q.id === selectedTriggerQuestion);
			setSelectedTriggerQuestionData(triggerQuestion || null);
			setAvailableOptions(triggerQuestion?.options || []);
		} else {
			setSelectedTriggerQuestionData(null);
			setAvailableOptions([]);
		}
	}, [selectedTriggerQuestion, sections]);

	// Get appropriate operators based on question type
	const getAvailableOperators = (questionType: string) => {
		if (questionType?.includes('MultipleChoice') || questionType?.includes('Radio')) {
			return [
				{ value: 'contains', label: 'Contains any option' },
				{ value: 'equals', label: 'Equals exactly' },
				{ value: 'not_equals', label: 'Does not equal' }
			];
		} else if (questionType?.includes('Range') || questionType?.includes('Number')) {
			return [
				{ value: 'equals', label: 'Equals' },
				{ value: 'greater_than', label: 'Greater than' },
				{ value: 'less_than', label: 'Less than' },
				{ value: 'between', label: 'Between' }
			];
		} else if (questionType?.includes('Text') || questionType?.includes('RichText')) {
			return [
				{ value: 'equals', label: 'Equals' },
				{ value: 'contains', label: 'Contains' },
				{ value: 'not_contains', label: 'Does not contain' }
			];
		} else if (questionType?.includes('Boolean')) {
			return [
				{ value: 'equals', label: 'Equals' }
			];
		}
		return [
			{ value: 'equals', label: 'Equals' }
		];
	};

	const handleSave = () => {
		const data: ConditionalLogicData = {
			is_conditional: isEnabled,
		};

		if (isEnabled && selectedTriggerQuestion) {
			data.trigger_question_id = selectedTriggerQuestion;
			data.trigger_response_type = triggerResponseType;
			data.operator = operator;
			
			// Process trigger values based on question type
			if (selectedTriggerQuestionData?.type.includes('MultipleChoice') || 
				selectedTriggerQuestionData?.type.includes('Radio')) {
				// For choice questions, values should be option IDs
				data.trigger_values = triggerValues.split(',').map(v => parseInt(v.trim())).filter(v => !isNaN(v));
			} else if (selectedTriggerQuestionData?.type.includes('Range') || 
					   selectedTriggerQuestionData?.type.includes('Number')) {
				// For numeric questions
				if (operator === 'between') {
					const [min, max] = triggerValues.split(',').map(v => parseFloat(v.trim()));
					data.trigger_values = [min, max].filter(v => !isNaN(v));
				} else {
					const numValue = parseFloat(triggerValues.trim());
					data.trigger_values = !isNaN(numValue) ? [numValue] : [];
				}
			} else if (selectedTriggerQuestionData?.type.includes('Boolean')) {
				// For boolean questions, convert to boolean
				data.trigger_values = [triggerValues.toLowerCase() === 'true'];
			} else {
				// For text questions, keep as strings
				data.trigger_values = triggerValues.split(',').map(v => v.trim()).filter(v => v.length > 0);
			}
		}

		onSave(data);
	};

	const renderTriggerValueInput = () => {
		if (!selectedTriggerQuestionData) {
			return (
				<input
					type="text"
					placeholder="Select a trigger question first"
					className="w-full p-2 border border-gray-300 rounded-md bg-gray-100 cursor-not-allowed"
					disabled
				/>
			);
		}

		const questionType = selectedTriggerQuestionData.type;

		if (questionType.includes('MultipleChoice') || questionType.includes('Radio')) {
			return (
				<div className="space-y-2">
					<select 
						multiple={questionType.includes('MultipleChoice')} 
						value={triggerValues.split(',').map(v => v.trim()).filter(v => v)}
						onChange={(e) => {
							const selectedValues = Array.from(e.target.selectedOptions, option => option.value);
							setTriggerValues(selectedValues.join(', '));
						}}
						className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
					>
						{availableOptions.map((option, index) => (
							<option key={option.id || index} value={option.id || index}>
								{option.text}
							</option>
						))}
					</select>
					<p className="text-xs text-gray-500">
						{questionType.includes('MultipleChoice') 
							? 'Hold Ctrl/Cmd to select multiple options' 
							: 'Select the option that should trigger this question'}
					</p>
				</div>
			);
		} else if (questionType.includes('Boolean')) {
			return (
				<select
					value={triggerValues || 'true'}
					onChange={(e) => setTriggerValues(e.target.value)}
					className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
				>
					<option value="true">Yes/True</option>
					<option value="false">No/False</option>
				</select>
			);
		} else if (questionType.includes('Range') || questionType.includes('Number')) {
			return (
				<input
					type={operator === 'between' ? 'text' : 'number'}
					value={triggerValues}
					onChange={(e) => setTriggerValues(e.target.value)}
					placeholder={operator === 'between' ? 'e.g., 5, 10' : 'Enter a number'}
					className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
				/>
			);
		} else {
			return (
				<input
					type="text"
					value={triggerValues}
					onChange={(e) => setTriggerValues(e.target.value)}
					placeholder="Enter text value"
					className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
				/>
			);
		}
	};

	const getPreviewText = () => {
		if (!isEnabled || !selectedTriggerQuestion || !selectedTriggerQuestionData) {
			return 'This question will always be shown.';
		}

		const questionText = selectedTriggerQuestionData.text.substring(0, 30) + '...';
		const operatorText = getAvailableOperators(selectedTriggerQuestionData.type)
			.find(op => op.value === operator)?.label || operator;
		
		return `This question will be shown when "${questionText}" ${operatorText.toLowerCase()} "${triggerValues || '[not set]'}"`;
	};

	if (!show) return null;

	return (
		<div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
			<Card className="max-w-4xl w-full max-h-[90vh] overflow-y-auto border border-purple-300 shadow-xl">
				<div className="p-6">
					{/* Header */}
					<div className="flex items-center justify-between mb-6">
						<h3 className="text-lg font-semibold text-gray-900">Conditional Logic</h3>
						<button
							onClick={onClose}
							className="text-gray-400 hover:text-gray-600 transition-colors"
						>
							<X className="w-5 h-5" />
						</button>
					</div>

					{/* Enable Toggle */}
					<div className="flex items-center space-x-3 mb-6 p-4 bg-gray-50 rounded-lg">
						<input
							type="checkbox"
							id="enable-conditional"
							checked={isEnabled}
							onChange={(e) => setIsEnabled(e.target.checked)}
							className="rounded text-purple-600 focus:ring-purple-500"
						/>
						<label htmlFor="enable-conditional" className="text-sm font-medium text-gray-700">
							Only show this question based on a previous answer
						</label>
					</div>

					{/* Conditional Logic Form */}
					{isEnabled && (
						<div className="space-y-6">
							{/* Trigger Question Selection */}
							<div>
								<label className="block text-sm font-medium text-gray-700 mb-2">
									Show this question when:
								</label>
								<select
									value={selectedTriggerQuestion || ''}
									onChange={(e) => setSelectedTriggerQuestion(Number(e.target.value) || null)}
									className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
								>
									<option value="">Select a previous question...</option>
									{previousQuestions.map(q => (
										<option key={q.id} value={q.id}>
											{q.sectionName} - {q.text.substring(0, 50)}{q.text.length > 50 ? '...' : ''} ({q.question_type_name})
										</option>
									))}
								</select>
								{previousQuestions.length === 0 && (
									<p className="text-sm text-gray-500 mt-1">
										No previous questions available. Add questions before this one to use conditional logic.
									</p>
								)}
							</div>

							{/* Operator Selection */}
							{selectedTriggerQuestionData && (
								<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label className="block text-sm font-medium text-gray-700 mb-2">
											Condition type:
										</label>
										<select
											value={operator}
											onChange={(e) => setOperator(e.target.value)}
											className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
										>
											{getAvailableOperators(selectedTriggerQuestionData.type).map(op => (
												<option key={op.value} value={op.value}>
													{op.label}
												</option>
											))}
										</select>
									</div>

									<div>
										<label className="block text-sm font-medium text-gray-700 mb-2">
											Trigger value(s):
										</label>
										{renderTriggerValueInput()}
									</div>
								</div>
							)}

							{/* Preview */}
							<div className="bg-blue-50 p-4 rounded border border-blue-200">
								<div className="flex items-start space-x-2">
									<CheckCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
									<div>
										<p className="text-sm font-medium text-blue-800 mb-1">Logic Preview:</p>
										<p className="text-sm text-blue-700">{getPreviewText()}</p>
									</div>
								</div>
							</div>
						</div>
					)}

					{/* Action Buttons */}
					<div className="flex items-center justify-end space-x-3 pt-6 border-t border-gray-200 mt-6">
						<button
							onClick={onClose}
							className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
						>
							Cancel
						</button>
						<button
							onClick={handleSave}
							className="px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700 transition-colors"
						>
							Save Logic
						</button>
					</div>
				</div>
			</Card>
		</div>
	);
};

export default ConditionalLogicModal;