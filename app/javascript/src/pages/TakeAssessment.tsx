"use client";

import React, { useState, useEffect } from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import { Card, Progress } from "flowbite-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import RouteGuard from "../components/RouteGuard";
import {
	FileText,
	ArrowLeft,
	ArrowRight,
	Save,
	CheckCircle,
	AlertCircle,
	Clock,
	User,
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";

interface AssessmentQuestion {
	id: number;
	text: string;
	type: string;
	question_type: string;
	question_type_name: string;
	order: number;
	is_required: boolean;
	active: boolean;
	meta_data: Record<string, any>;
	options: AssessmentQuestionOption[];
}

interface AssessmentQuestionOption {
	id: number;
	text: string;
	order: number;
	active: boolean;
}

interface AssessmentSection {
	id: number;
	name: string;
	order: number;
	questions_count: number;
	questions: AssessmentQuestion[];
}

interface Assessment {
	id: number;
	title: string;
	description: string;
	sections_count: number;
	questions_count: number;
	sections: AssessmentSection[];
}

interface AssessmentResponseSession {
	id: number;
	state: 'draft' | 'in_progress' | 'completed' | 'submitted';
	progress_percentage: number;
	current_section_id?: number;
	current_question_id?: number;
	started_at?: string;
	assessment: Assessment;
}

interface QuestionResponse {
	question_id: number;
	selected_option_ids?: number[];
	number?: number;
	text?: string;
	date?: string;
	boolean?: boolean;
}

// Static data based on the assessment structure
const getAssessmentData = (assessmentId: string): Assessment => {
	const assessmentData: Record<string, Assessment> = {
		"1": {
			id: 1,
			title: "Global Technology Survey",
			description: "A comprehensive survey about technology usage and preferences across different regions.",
			sections_count: 3,
			questions_count: 12,
			sections: [
				{
					id: 1,
					name: "Technology Infrastructure",
					order: 1,
					questions_count: 4,
					questions: [
						{
							id: 1,
							text: "What is your primary technology platform?",
							type: "AssessmentQuestions::MultipleChoice",
							question_type: "multiple_choice",
							question_type_name: "Multiple Choice",
							order: 1,
							is_required: true,
							active: true,
							meta_data: {},
							options: [
								{ id: 1, text: "Cloud-based solutions", order: 1, active: true },
								{ id: 2, text: "On-premise infrastructure", order: 2, active: true },
								{ id: 3, text: "Hybrid approach", order: 3, active: true },
								{ id: 4, text: "Mobile-first solutions", order: 4, active: true }
							]
						},
						{
							id: 2,
							text: "How would you rate your organization's digital maturity?",
							type: "AssessmentQuestions::Radio",
							question_type: "radio",
							question_type_name: "Single Choice",
							order: 2,
							is_required: true,
							active: true,
							meta_data: {},
							options: [
								{ id: 5, text: "Beginner (1-2)", order: 1, active: true },
								{ id: 6, text: "Intermediate (3-4)", order: 2, active: true },
								{ id: 7, text: "Advanced (5)", order: 3, active: true }
							]
						},
						{
							id: 3,
							text: "Do you have a dedicated IT team?",
							type: "AssessmentQuestions::BooleanType",
							question_type: "boolean",
							question_type_name: "Yes/No",
							order: 3,
							is_required: true,
							active: true,
							meta_data: {},
							options: []
						},
						{
							id: 4,
							text: "What is your annual technology budget? (USD)",
							type: "AssessmentQuestions::RangeType",
							question_type: "range",
							question_type_name: "Number Range",
							order: 4,
							is_required: false,
							active: true,
							meta_data: { min: 0, max: 1000000 },
							options: []
						}
					]
				},
				{
					id: 2,
					name: "Digital Transformation",
					order: 2,
					questions_count: 4,
					questions: [
						{
							id: 5,
							text: "Which digital transformation initiatives are you currently pursuing?",
							type: "AssessmentQuestions::MultipleChoice",
							question_type: "multiple_choice",
							question_type_name: "Multiple Choice",
							order: 1,
							is_required: true,
							active: true,
							meta_data: {},
							options: [
								{ id: 8, text: "Process automation", order: 1, active: true },
								{ id: 9, text: "Data analytics", order: 2, active: true },
								{ id: 10, text: "Customer experience enhancement", order: 3, active: true },
								{ id: 11, text: "Digital marketing", order: 4, active: true },
								{ id: 12, text: "Remote work capabilities", order: 5, active: true }
							]
						},
						{
							id: 6,
							text: "When did you start your digital transformation journey?",
							type: "AssessmentQuestions::DateType",
							question_type: "date",
							question_type_name: "Date",
							order: 2,
							is_required: true,
							active: true,
							meta_data: {},
							options: []
						},
						{
							id: 7,
							text: "Is digital transformation a strategic priority for your organization?",
							type: "AssessmentQuestions::BooleanType",
							question_type: "boolean",
							question_type_name: "Yes/No",
							order: 3,
							is_required: true,
							active: true,
							meta_data: {},
							options: []
						},
						{
							id: 8,
							text: "Please describe your biggest digital transformation challenge.",
							type: "AssessmentQuestions::RichText",
							question_type: "rich_text",
							question_type_name: "Text Area",
							order: 4,
							is_required: false,
							active: true,
							meta_data: {},
							options: []
						}
					]
				},
				{
					id: 3,
					name: "Future Planning",
					order: 3,
					questions_count: 4,
					questions: [
						{
							id: 9,
							text: "What are your technology priorities for the next 2 years?",
							type: "AssessmentQuestions::MultipleChoice",
							question_type: "multiple_choice",
							question_type_name: "Multiple Choice",
							order: 1,
							is_required: true,
							active: true,
							meta_data: {},
							options: [
								{ id: 13, text: "Artificial Intelligence integration", order: 1, active: true },
								{ id: 14, text: "Cybersecurity enhancement", order: 2, active: true },
								{ id: 15, text: "Cloud migration", order: 3, active: true },
								{ id: 16, text: "Data governance", order: 4, active: true },
								{ id: 17, text: "Mobile optimization", order: 5, active: true }
							]
						},
						{
							id: 10,
							text: "Rate your confidence in achieving your technology goals (1-10)",
							type: "AssessmentQuestions::RangeType",
							question_type: "range",
							question_type_name: "Number Range",
							order: 2,
							is_required: true,
							active: true,
							meta_data: { min: 1, max: 10 },
							options: []
						},
						{
							id: 11,
							text: "Do you plan to increase technology spending next year?",
							type: "AssessmentQuestions::BooleanType",
							question_type: "boolean",
							question_type_name: "Yes/No",
							order: 3,
							is_required: true,
							active: true,
							meta_data: {},
							options: []
						},
						{
							id: 12,
							text: "Any additional comments about your technology strategy?",
							type: "AssessmentQuestions::RichText",
							question_type: "rich_text",
							question_type_name: "Text Area",
							order: 4,
							is_required: false,
							active: true,
							meta_data: {},
							options: []
						}
					]
				}
			]
		}
		// Add other assessments as needed
	};

	return assessmentData[assessmentId] || assessmentData["1"];
};

const getResponseSession = (assessmentId: string, sessionState: 'start' | 'continue'): AssessmentResponseSession => {
	const assessment = getAssessmentData(assessmentId);
	
	if (sessionState === 'start') {
		return {
			id: Date.now(), // Generate unique ID
			state: 'draft',
			progress_percentage: 0,
			current_section_id: assessment.sections[0]?.id,
			current_question_id: assessment.sections[0]?.questions[0]?.id,
			assessment
		};
	} else {
		// Continue scenario - partial progress
		return {
			id: Date.now(),
			state: 'in_progress',
			progress_percentage: 65,
			current_section_id: assessment.sections[1]?.id,
			current_question_id: assessment.sections[1]?.questions[0]?.id,
			started_at: "2024-12-01T14:15:00.000Z",
			assessment
		};
	}
};

const TakeAssessment: React.FC = () => {
	const { assessmentId } = useParams<{ assessmentId: string }>();
	const navigate = useNavigate();
	const { user } = useAuth();
	const [responseSession, setResponseSession] = useState<AssessmentResponseSession | null>(null);
	const [currentSectionIndex, setCurrentSectionIndex] = useState(0);
	const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
	const [responses, setResponses] = useState<Record<number, QuestionResponse>>({});
	const [loading, setLoading] = useState(true);
	const [saving, setSaving] = useState(false);

	useEffect(() => {
		if (assessmentId) {
			// Determine if this is start or continue based on URL
			const isStart = window.location.pathname.includes('/start');
			const session = getResponseSession(assessmentId, isStart ? 'start' : 'continue');
			setResponseSession(session);
			
			// Set current section and question based on session state
			if (session.current_section_id && session.current_question_id) {
				const sectionIndex = session.assessment.sections.findIndex(s => s.id === session.current_section_id);
				const section = session.assessment.sections[sectionIndex];
				const questionIndex = section?.questions.findIndex(q => q.id === session.current_question_id) || 0;
				
				setCurrentSectionIndex(sectionIndex >= 0 ? sectionIndex : 0);
				setCurrentQuestionIndex(questionIndex);
			}
			
			setLoading(false);
		}
	}, [assessmentId]);

	const currentSection = responseSession?.assessment.sections[currentSectionIndex];
	const currentQuestion = currentSection?.questions[currentQuestionIndex];
	const totalQuestions = responseSession?.assessment.questions_count || 0;
	const answeredQuestions = Object.keys(responses).length;
	const progress = totalQuestions > 0 ? (answeredQuestions / totalQuestions) * 100 : 0;

	const handleResponseChange = (questionId: number, response: Partial<QuestionResponse>) => {
		setResponses(prev => ({
			...prev,
			[questionId]: { ...prev[questionId], question_id: questionId, ...response }
		}));
	};

	const handleNextQuestion = () => {
		if (!currentSection || !currentQuestion) return;

		// Check if current question is required and not answered
		if (currentQuestion.is_required && !responses[currentQuestion.id]) {
			alert('Please answer this required question before proceeding.');
			return;
		}

		// Move to next question in current section
		if (currentQuestionIndex < currentSection.questions.length - 1) {
			setCurrentQuestionIndex(currentQuestionIndex + 1);
		} else {
			// Move to next section
			if (currentSectionIndex < (responseSession?.assessment.sections.length || 0) - 1) {
				setCurrentSectionIndex(currentSectionIndex + 1);
				setCurrentQuestionIndex(0);
			} else {
				// Assessment complete
				handleCompleteAssessment();
			}
		}
	};

	const handlePreviousQuestion = () => {
		if (!currentSection) return;

		// Move to previous question in current section
		if (currentQuestionIndex > 0) {
			setCurrentQuestionIndex(currentQuestionIndex - 1);
		} else {
			// Move to previous section
			if (currentSectionIndex > 0) {
				const prevSectionIndex = currentSectionIndex - 1;
				const prevSection = responseSession?.assessment.sections[prevSectionIndex];
				if (prevSection) {
					setCurrentSectionIndex(prevSectionIndex);
					setCurrentQuestionIndex(prevSection.questions.length - 1);
				}
			}
		}
	};

	const handleSaveProgress = async () => {
		setSaving(true);
		// Simulate API call to save progress
		setTimeout(() => {
			setSaving(false);
			// Update session state
			if (responseSession) {
				setResponseSession(prev => prev ? {
					...prev,
					state: 'in_progress',
					progress_percentage: progress,
					current_section_id: currentSection?.id,
					current_question_id: currentQuestion?.id
				} : null);
			}
		}, 1000);
	};

	const handleCompleteAssessment = async () => {
		setSaving(true);
		// Simulate API call to complete assessment
		setTimeout(() => {
			setSaving(false);
			if (responseSession) {
				setResponseSession(prev => prev ? {
					...prev,
					state: 'completed',
					progress_percentage: 100
				} : null);
			}
			// Navigate back to assessments with success message
			navigate('/app/my-assessments', { 
				state: { message: 'Assessment completed successfully!' }
			});
		}, 1500);
	};

	const renderQuestion = () => {
		if (!currentQuestion) return null;

		const response = responses[currentQuestion.id];

		switch (currentQuestion.question_type) {
			case 'multiple_choice':
				return (
					<div className="space-y-3">
						{currentQuestion.options.map((option) => (
							<label key={option.id} className="flex items-center space-x-3 p-3 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer">
								<input
									type="checkbox"
									checked={response?.selected_option_ids?.includes(option.id) || false}
									onChange={(e) => {
										const currentIds = response?.selected_option_ids || [];
										const newIds = e.target.checked 
											? [...currentIds, option.id]
											: currentIds.filter(id => id !== option.id);
										handleResponseChange(currentQuestion.id, { selected_option_ids: newIds });
									}}
									className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500"
								/>
								<span className="text-sm font-medium text-gray-900">{option.text}</span>
							</label>
						))}
					</div>
				);

			case 'radio':
				return (
					<div className="space-y-3">
						{currentQuestion.options.map((option) => (
							<label key={option.id} className="flex items-center space-x-3 p-3 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer">
								<input
									type="radio"
									name={`question-${currentQuestion.id}`}
									checked={response?.selected_option_ids?.[0] === option.id || false}
									onChange={() => {
										handleResponseChange(currentQuestion.id, { selected_option_ids: [option.id] });
									}}
									className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
								/>
								<span className="text-sm font-medium text-gray-900">{option.text}</span>
							</label>
						))}
					</div>
				);

			case 'boolean':
				return (
					<div className="flex space-x-4">
						<label className="flex items-center space-x-2 cursor-pointer">
							<input
								type="radio"
								name={`question-${currentQuestion.id}`}
								checked={response?.boolean === true}
								onChange={() => handleResponseChange(currentQuestion.id, { boolean: true })}
								className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
							/>
							<span className="text-sm font-medium text-gray-900">Yes</span>
						</label>
						<label className="flex items-center space-x-2 cursor-pointer">
							<input
								type="radio"
								name={`question-${currentQuestion.id}`}
								checked={response?.boolean === false}
								onChange={() => handleResponseChange(currentQuestion.id, { boolean: false })}
								className="w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 focus:ring-purple-500"
							/>
							<span className="text-sm font-medium text-gray-900">No</span>
						</label>
					</div>
				);

			case 'range':
				const min = currentQuestion.meta_data?.min || 0;
				const max = currentQuestion.meta_data?.max || 100;
				return (
					<div className="space-y-4">
						<input
							type="number"
							min={min}
							max={max}
							value={response?.number || ''}
							onChange={(e) => handleResponseChange(currentQuestion.id, { number: parseInt(e.target.value) || 0 })}
							placeholder={`Enter a number between ${min} and ${max}`}
							className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
						/>
						<div className="text-xs text-gray-500">
							Range: {min} - {max}
						</div>
					</div>
				);

			case 'date':
				return (
					<input
						type="date"
						value={response?.date || ''}
						onChange={(e) => handleResponseChange(currentQuestion.id, { date: e.target.value })}
						className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
					/>
				);

			case 'rich_text':
				return (
					<textarea
						rows={4}
						value={response?.text || ''}
						onChange={(e) => handleResponseChange(currentQuestion.id, { text: e.target.value })}
						placeholder="Enter your response..."
						className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
					/>
				);

			default:
				return (
					<div className="text-gray-500 italic">
						Question type "{currentQuestion.question_type}" not yet implemented.
					</div>
				);
		}
	};

	if (loading) {
		return (
			<RouteGuard requireAdmin={false}>
				<DashboardLayout>
					<DashboardLayout.Sidebar>
						<ApplicationSidebar />
					</DashboardLayout.Sidebar>
					<DashboardLayout.Content>
						<div className="flex items-center justify-center h-96">
							<div className="text-center">
								<div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto mb-4"></div>
								<p className="text-gray-500">Loading assessment...</p>
							</div>
						</div>
					</DashboardLayout.Content>
				</DashboardLayout>
			</RouteGuard>
		);
	}

	if (!responseSession) {
		return (
			<RouteGuard requireAdmin={false}>
				<DashboardLayout>
					<DashboardLayout.Sidebar>
						<ApplicationSidebar />
					</DashboardLayout.Sidebar>
					<DashboardLayout.Content>
						<div className="text-center py-12">
							<AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
							<h3 className="text-lg font-medium text-gray-900 mb-2">Assessment Not Found</h3>
							<p className="text-gray-500 mb-4">The requested assessment could not be loaded.</p>
							<button
								onClick={() => navigate('/app/my-assessments')}
								className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors mx-auto"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back to Assessments
							</button>
						</div>
					</DashboardLayout.Content>
				</DashboardLayout>
			</RouteGuard>
		);
	}

	return (
		<RouteGuard requireAdmin={false}>
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>

				<DashboardLayout.Content>
					{/* Header */}
					<div className="flex items-center justify-between mb-8">
						<div className="flex items-center space-x-4">
							<button
								onClick={() => navigate('/app/my-assessments')}
								className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
							>
								<ArrowLeft className="w-4 h-4 mr-2" />
								Back
							</button>
							<div>
								<h1 className="text-2xl font-bold text-gray-900">{responseSession.assessment.title}</h1>
								<p className="text-gray-600 mt-1">{responseSession.assessment.description}</p>
							</div>
						</div>
						<div className="flex items-center space-x-3">
							<div className="text-sm text-gray-500">
								<User className="w-4 h-4 inline mr-1" />
								{user?.display_name || user?.full_name || 'User'}
							</div>
						</div>
					</div>

					{/* Progress Section */}
					<Card className="mb-8 border border-gray-200 shadow-none">
						<div className="flex items-center justify-between mb-4">
							<div className="flex items-center space-x-4">
								<div className="flex items-center space-x-2">
									<Clock className="w-5 h-5 text-gray-400" />
									<span className="text-sm font-medium text-gray-600">
										Section {currentSectionIndex + 1} of {responseSession.assessment.sections_count}
									</span>
								</div>
								<div className="w-px h-6 bg-gray-300"></div>
								<div className="flex items-center space-x-2">
									<FileText className="w-5 h-5 text-gray-400" />
									<span className="text-sm font-medium text-gray-600">
										Question {currentQuestionIndex + 1} of {currentSection?.questions_count || 0}
									</span>
								</div>
							</div>
							<span className="text-sm font-medium text-purple-600">
								{Math.round(progress)}% Complete
							</span>
						</div>
						<Progress 
							progress={progress} 
							color="purple" 
							className="mb-2"
						/>
						<div className="text-xs text-gray-500">
							{answeredQuestions} of {totalQuestions} questions answered
						</div>
					</Card>

					{/* Question Section */}
					<div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
						{/* Section Navigation */}
						<div className="lg:col-span-1">
							<Card className="border border-gray-200 shadow-none">
								<h3 className="text-lg font-medium text-gray-900 mb-4">Sections</h3>
								<div className="space-y-2">
									{responseSession.assessment.sections.map((section, index) => (
										<div
											key={section.id}
											className={`p-3 rounded-lg border ${
												index === currentSectionIndex
													? 'border-purple-200 bg-purple-50 text-purple-900'
													: 'border-gray-200 text-gray-600 hover:bg-gray-50'
											} transition-colors`}
										>
											<div className="flex items-center justify-between">
												<span className="text-sm font-medium">{section.name}</span>
												{index < currentSectionIndex && (
													<CheckCircle className="w-4 h-4 text-green-500" />
												)}
												{index === currentSectionIndex && (
													<Clock className="w-4 h-4 text-purple-500" />
												)}
											</div>
											<div className="text-xs text-gray-500 mt-1">
												{section.questions_count} questions
											</div>
										</div>
									))}
								</div>
							</Card>
						</div>

						{/* Question Content */}
						<div className="lg:col-span-3">
							<Card className="border border-gray-200 shadow-none">
								{currentSection && currentQuestion && (
									<>
										{/* Section Header */}
										<div className="mb-6 pb-4 border-b border-gray-200">
											<h2 className="text-xl font-semibold text-gray-900 mb-2">
												{currentSection.name}
											</h2>
											<div className="flex items-center space-x-4 text-sm text-gray-500">
												<span>Question {currentQuestionIndex + 1} of {currentSection.questions_count}</span>
												{currentQuestion.is_required && (
													<span className="flex items-center text-red-600">
														<AlertCircle className="w-3 h-3 mr-1" />
														Required
													</span>
												)}
											</div>
										</div>

										{/* Question */}
										<div className="mb-8">
											<h3 className="text-lg font-medium text-gray-900 mb-4">
												{currentQuestion.text}
											</h3>
											{renderQuestion()}
										</div>

										{/* Navigation Buttons */}
										<div className="flex items-center justify-between pt-6 border-t border-gray-200">
											<button
												onClick={handlePreviousQuestion}
												disabled={currentSectionIndex === 0 && currentQuestionIndex === 0}
												className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
											>
												<ArrowLeft className="w-4 h-4 mr-2" />
												Previous
											</button>

											<div className="flex items-center space-x-3">
												<button
													onClick={handleSaveProgress}
													disabled={saving}
													className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
												>
													{saving ? (
														<div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-600 mr-2"></div>
													) : (
														<Save className="w-4 h-4 mr-2" />
													)}
													Save Progress
												</button>

												<button
													onClick={handleNextQuestion}
													className="flex items-center px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
												>
													{currentSectionIndex === (responseSession.assessment.sections.length - 1) && 
													 currentQuestionIndex === (currentSection.questions.length - 1) ? (
														<>
															<CheckCircle className="w-4 h-4 mr-2" />
															Complete Assessment
														</>
													) : (
														<>
															Next
															<ArrowRight className="w-4 h-4 ml-2" />
														</>
													)}
												</button>
											</div>
										</div>
									</>
								)}
							</Card>
						</div>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		</RouteGuard>
	);
};

export default TakeAssessment;

// Export route configurations for both start and continue
export const startRouteConfig = {
	path: "/app/assessments/:assessmentId/start",
	Component: TakeAssessment,
} as RouteObject;

export const continueRouteConfig = {
	path: "/app/assessments/:assessmentId/continue", 
	Component: TakeAssessment,
} as RouteObject;