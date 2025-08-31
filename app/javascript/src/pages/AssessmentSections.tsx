"use client";

import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate, RouteObject } from "react-router";
import {
	Card,
	Alert,
} from "flowbite-react";
import { 
	ArrowLeft, 
	Plus, 
	Edit, 
	Trash2, 
	FileText, 
	AlertCircle,
	CheckSquare,
	Circle,
	Sliders,
	Calendar,
	Upload,
	GripVertical,
	X,
	Move
} from "lucide-react";
import DashboardLayout from "../layouts/DashboardLayout";
import ApplicationSidebar from "../components/Sidebar/Sidebar";
import { fetchAssessment, fetchAssessmentSections, createAssessmentSection, createAssessmentQuestion, updateAssessmentQuestion, deleteAssessmentQuestion, updateQuestionOption, deleteAssessmentSection } from "../api/assessments";

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

interface AssessmentQuestion {
	id: number;
	text: string;
	type: string;
	question_type_name: string;
	sub_type: string;
	order: number;
	is_required: boolean;
	active: boolean;
	meta_data: any;
	options: any[];
}

interface AssessmentSection {
	id: number;
	name: string;
	order: number;
	is_conditional: boolean;
	has_country_restrictions: boolean;
	restricted_countries: string[];
	questions_count: number;
	questions: AssessmentQuestion[];
	created_at: string;
	updated_at: string;
}

interface SectionType {
	id: string;
	name: string;
	description: string;
	icon: React.ComponentType<any>;
	color: string;
	bgColor: string;
}

const sectionTypes: SectionType[] = [
	{
		id: "basic",
		name: "Text",
		description: "Short answer or paragraph text",
		icon: FileText,
		color: "text-blue-600",
		bgColor: "bg-blue-50"
	},
	{
		id: "multiple_choice",
		name: "Multiple choice",
		description: "Select multiple options",
		icon: CheckSquare,
		color: "text-green-600",
		bgColor: "bg-green-50"
	},
	{
		id: "single_choice", 
		name: "Multiple choice",
		description: "Select one option",
		icon: Circle,
		color: "text-purple-600",
		bgColor: "bg-purple-50"
	},
	{
		id: "rating_scale",
		name: "Linear scale",
		description: "Rating or numeric scale",
		icon: Sliders,
		color: "text-red-600",
		bgColor: "bg-red-50"
	},
	{
		id: "date_time",
		name: "Date",
		description: "Date and time picker",
		icon: Calendar,
		color: "text-orange-600",
		bgColor: "bg-orange-50"
	},
	{
		id: "file_upload",
		name: "File upload",
		description: "Upload documents or images",
		icon: Upload,
		color: "text-yellow-600",
		bgColor: "bg-yellow-50"
	}
];

export default function AssessmentSections() {
	const { id } = useParams();
	const navigate = useNavigate();
	const [assessment, setAssessment] = useState<Assessment | null>(null);
	const [sections, setSections] = useState<AssessmentSection[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [showSectionTypes, setShowSectionTypes] = useState(false);
	const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
	const [showSaveBar, setShowSaveBar] = useState(false);
	const [editingQuestion, setEditingQuestion] = useState<{ sectionId: number; questionId?: number } | null>(null);
	const [showQuestionTypes, setShowQuestionTypes] = useState<{ sectionId: number } | null>(null);
	const [editingOption, setEditingOption] = useState<{ questionId: number; optionIndex: number } | null>(null);
	const [showConditionalLogic, setShowConditionalLogic] = useState<{ questionId: number; sectionId: number } | null>(null);
	const sectionPopoverRef = useRef<HTMLDivElement>(null);

	useEffect(() => {
		const loadData = async () => {
			if (!id) return;
			
			try {
				const [assessmentData, sectionsData] = await Promise.all([
					fetchAssessment(Number(id)),
					fetchAssessmentSections(Number(id))
				]);
				setAssessment(assessmentData);
				setSections(sectionsData);
			} catch (err) {
				console.error('Failed to fetch data:', err);
				setError(err instanceof Error ? err.message : 'Failed to load assessment');
			} finally {
				setLoading(false);
			}
		};

		loadData();
	}, [id]);

	// Click outside to close section popover
	useEffect(() => {
		function handleClickOutside(event: MouseEvent) {
			if (sectionPopoverRef.current && !sectionPopoverRef.current.contains(event.target as Node)) {
				setShowSectionTypes(false);
			}
		}

		if (showSectionTypes) {
			document.addEventListener('mousedown', handleClickOutside);
		}

		return () => {
			document.removeEventListener('mousedown', handleClickOutside);
		};
	}, [showSectionTypes]);

	const handleBack = () => {
		navigate('/app');
	};

	const handleAddSection = (sectionType: SectionType) => {
		if (!id) return;
		
		const newSectionName = `${sectionType.name} ${sections.length + 1}`;
		createAssessmentSection(Number(id), { name: newSectionName })
			.then(() => fetchAssessmentSections(Number(id)))
			.then(updatedSections => setSections(updatedSections))
			.catch(err => setError(err.message));
		
		setShowSectionTypes(false);
	};

	const handleEditSection = (sectionId: number) => {
		console.log('Edit section:', sectionId);
	};

	const handleAddQuestion = (sectionId: number) => {
		setShowQuestionTypes({ sectionId });
	};

	const handleCreateQuestion = async (sectionId: number, questionType: string) => {
		if (!id) return;
		
		const questionData = {
			type: questionType,
			text: { en: "Untitled Question" },
			is_required: false,
			active: true
		};
		
		try {
			await createAssessmentQuestion(Number(id), sectionId, questionData);
			// Reload sections to show new question
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
			setShowQuestionTypes(null);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to create question');
		}
	};

	const handleDeleteQuestion = async (sectionId: number, questionId: number) => {
		if (!id) return;
		
		if (!confirm('Are you sure you want to delete this question?')) {
			return;
		}
		
		try {
			await deleteAssessmentQuestion(Number(id), sectionId, questionId);
			// Reload sections to remove deleted question
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to delete question');
		}
	};

	const handleEditQuestion = (sectionId: number, questionId: number) => {
		setEditingQuestion({ sectionId, questionId });
	};

	const handleUpdateQuestion = async (sectionId: number, questionId: number, updates: any) => {
		if (!id) return;
		
		try {
			await updateAssessmentQuestion(Number(id), sectionId, questionId, updates);
			// Reload sections to show updated question
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setEditingQuestion(null);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to update question');
		}
	};

	const handleDeleteSection = async (sectionId: number) => {
		if (!id) return;
		
		const section = sections.find(s => s.id === sectionId);
		const questionCount = section?.questions?.length || 0;
		
		let confirmMessage = 'Are you sure you want to delete this section?';
		if (questionCount > 0) {
			confirmMessage += ` This will also delete ${questionCount} question${questionCount === 1 ? '' : 's'}.`;
		}
		
		if (!confirm(confirmMessage)) {
			return;
		}
		
		try {
			await deleteAssessmentSection(Number(id), sectionId);
			// Reload sections to remove deleted section
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to delete section');
		}
	};

	const handleEditOption = (questionId: number, optionIndex: number) => {
		setEditingOption({ questionId, optionIndex });
	};

	const handleUpdateOption = async (sectionId: number, questionId: number, optionIndex: number, newText: string) => {
		if (!id) return;
		
		// Find the question and get the option ID
		const section = sections.find(s => s.id === sectionId);
		const question = section?.questions.find(q => q.id === questionId);
		if (!question || !question.options || !question.options[optionIndex]) return;
		
		const option = question.options[optionIndex];
		if (!option || !option.id) {
			console.error('Option not found or missing ID:', option);
			return;
		}
		const optionId = option.id;
		
		try {
			// Use the dedicated option update API
			await updateQuestionOption(questionId, optionId, {
				text: { en: newText }
			});
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setEditingOption(null);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to update option');
		}
	};

	const handleToggleConditionalLogic = (questionId: number, sectionId: number) => {
		setShowConditionalLogic({ questionId, sectionId });
	};

	const handleUpdateConditionalLogic = async (sectionId: number, questionId: number, conditionalData: any) => {
		if (!id) return;
		
		try {
			await updateAssessmentQuestion(Number(id), sectionId, questionId, {
				is_conditional: conditionalData.is_conditional,
				trigger_question_id: conditionalData.trigger_question_id,
				trigger_response_type: conditionalData.trigger_response_type,
				trigger_values: conditionalData.trigger_values,
				operator: conditionalData.operator
			});
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setShowConditionalLogic(null);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to update conditional logic');
		}
	};

	const handleMoveQuestion = async (sectionId: number, questionId: number, direction: 'up' | 'down') => {
		if (!id) return;
		
		const section = sections.find(s => s.id === sectionId);
		if (!section || !section.questions) return;
		
		const questionIndex = section.questions.findIndex(q => q.id === questionId);
		if (questionIndex === -1) return;
		
		// Check if move is valid
		if ((direction === 'up' && questionIndex === 0) || 
				(direction === 'down' && questionIndex === section.questions.length - 1)) {
			return;
		}
		
		const newIndex = direction === 'up' ? questionIndex - 1 : questionIndex + 1;
		const currentOrder = section.questions[questionIndex].order;
		const targetOrder = section.questions[newIndex].order;
		
		try {
			// Update orders by swapping
			await updateAssessmentQuestion(Number(id), sectionId, questionId, { order: targetOrder });
			await updateAssessmentQuestion(Number(id), sectionId, section.questions[newIndex].id, { order: currentOrder });
			
			// Reload sections
			const updatedSections = await fetchAssessmentSections(Number(id));
			setSections(updatedSections);
			setHasUnsavedChanges(true);
			setShowSaveBar(true);
		} catch (err) {
			setError(err instanceof Error ? err.message : 'Failed to reorder question');
		}
	};

	const handleSaveChanges = () => {
		setHasUnsavedChanges(false);
		setShowSaveBar(false);
		console.log('Saving changes...');
	};

	const handleDiscardChanges = () => {
		setHasUnsavedChanges(false);
		setShowSaveBar(false);
		console.log('Discarding changes...');
	};

	const availableQuestionTypes = [
		{
			type: "AssessmentQuestions::TextType",
			name: "Text Input",
			description: "Single line text input",
			icon: FileText,
			color: "text-blue-600",
			bgColor: "bg-blue-50"
		},
		{
			type: "AssessmentQuestions::RichText",
			name: "Long Answer",
			description: "Multi-line text input",
			icon: FileText,
			color: "text-blue-600",
			bgColor: "bg-blue-50"
		},
		{
			type: "AssessmentQuestions::MultipleChoice",
			name: "Multiple Choice",
			description: "Multiple selections allowed",
			icon: CheckSquare,
			color: "text-green-600",
			bgColor: "bg-green-50"
		},
		{
			type: "AssessmentQuestions::Radio",
			name: "Single Choice",
			description: "Only one selection allowed",
			icon: Circle,
			color: "text-purple-600",
			bgColor: "bg-purple-50"
		},
		{
			type: "AssessmentQuestions::RangeType",
			name: "Scale",
			description: "Rating or numeric scale",
			icon: Sliders,
			color: "text-red-600",
			bgColor: "bg-red-50"
		},
		{
			type: "AssessmentQuestions::DateType",
			name: "Date",
			description: "Date picker input",
			icon: Calendar,
			color: "text-orange-600",
			bgColor: "bg-orange-50"
		},
		{
			type: "AssessmentQuestions::FileUpload",
			name: "File Upload",
			description: "Upload documents or images",
			icon: Upload,
			color: "text-yellow-600",
			bgColor: "bg-yellow-50"
		}
	];

	if (loading) {
		return (
			<DashboardLayout>
				<DashboardLayout.Sidebar>
					<ApplicationSidebar />
				</DashboardLayout.Sidebar>
				<DashboardLayout.Content>
					<div className="flex items-center justify-center min-h-96">
						<div className="text-center">
							<div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
							<p className="text-gray-600">Loading assessment...</p>
						</div>
					</div>
				</DashboardLayout.Content>
			</DashboardLayout>
		);
	}

	return (
		<DashboardLayout>
			<DashboardLayout.Sidebar>
				<ApplicationSidebar />
			</DashboardLayout.Sidebar>

			<DashboardLayout.Content>
				{/* Header */}
				<div className="flex items-center justify-between mb-6">
					<div className="flex items-center space-x-4">
						<button 
							onClick={handleBack}
							className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
						>
							<ArrowLeft className="w-4 h-4 mr-2" />
							Back
						</button>
						<div>
							<h1 className="text-xl font-semibold text-gray-900">{assessment?.title}</h1>
							<p className="text-sm text-gray-600">Assessment Builder</p>
						</div>
					</div>
				</div>

				{/* Save/Discard Bar */}
				{showSaveBar && (
					<div className="fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50">
						<div className="bg-white border border-gray-300 rounded-lg shadow-lg px-6 py-3 flex items-center space-x-4">
							<span className="text-sm text-gray-700">You have unsaved changes</span>
							<div className="flex items-center space-x-2">
								<button 
									onClick={handleDiscardChanges}
									className="px-3 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
								>
									Discard
								</button>
								<button 
									onClick={handleSaveChanges}
									className="px-4 py-1.5 text-sm font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700 transition-colors"
								>
									Save
								</button>
							</div>
						</div>
					</div>
				)}

				{/* Google Forms Style Builder */}
				<div className="max-w-4xl mx-auto">
					<div className="space-y-6">
						{/* Assessment Header */}
						<div className="mb-6">
							<h1 className="text-2xl font-bold text-gray-900 mb-2">{assessment?.title}</h1>
							{assessment?.description && (
								<p className="text-gray-600 text-lg">{assessment.description}</p>
							)}
						</div>

						{/* Existing Sections with Questions */}
						{sections.map((section, sectionIndex) => (
							<Card key={section.id} className="shadow-sm border border-gray-200 group">
								<div className="p-6">
									{/* Section Header */}
									<div className="flex items-center justify-between mb-6">
										<div className="flex items-center space-x-3">
											<GripVertical className="w-4 h-4 text-gray-400 cursor-move" />
											<div>
												<h3 className="text-lg font-semibold text-gray-900">{section.name}</h3>
												<p className="text-sm text-gray-500">Section {section.order}</p>
											</div>
										</div>
										<div className="flex items-center space-x-2 opacity-0 group-hover:opacity-100 transition-opacity">
											<button 
												onClick={() => handleEditSection(section.id)}
												className="p-2 rounded-md hover:bg-gray-100 transition-colors"
											>
												<Edit className="w-4 h-4 text-gray-600" />
											</button>
											<button 
												onClick={() => handleDeleteSection(section.id)}
												className="p-2 rounded-md hover:bg-red-100 transition-colors"
												title="Delete section"
											>
												<Trash2 className="w-4 h-4 text-red-600" />
											</button>
										</div>
									</div>

									{/* Questions in this section */}
									<div className="space-y-4">
										{section.questions && section.questions.length > 0 ? (
											section.questions.map((question, questionIndex) => (
												<div key={question.id} className="border border-gray-200 rounded-lg p-4 bg-gray-50">
													<div className="flex items-start justify-between">
														<div className="flex-1">
															<div className="flex items-center space-x-2 mb-2">
																<span className="text-sm font-medium text-gray-900">
																	Q{questionIndex + 1}
																</span>
																{question.is_required && (
																	<span className="text-red-500 text-sm">*</span>
																)}
																<span className="text-xs text-gray-500 bg-gray-200 px-2 py-1 rounded">
																	{question.question_type_name}
																</span>
															</div>
															
															{/* Question text editing */}
															{editingQuestion?.sectionId === section.id && editingQuestion?.questionId === question.id ? (
																<div className="mb-3">
																	<input 
																		type="text"
																		defaultValue={question.text}
																		className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
																		placeholder="Question text"
																		onKeyDown={(e) => {
																			if (e.key === 'Enter') {
																				const newText = (e.target as HTMLInputElement).value;
																				handleUpdateQuestion(section.id, question.id, { text: { en: newText } });
																			} else if (e.key === 'Escape') {
																				setEditingQuestion(null);
																			}
																		}}
																		onBlur={(e) => {
																			const newText = e.target.value;
																			if (newText !== question.text) {
																				handleUpdateQuestion(section.id, question.id, { text: { en: newText } });
																			} else {
																				setEditingQuestion(null);
																			}
																		}}
																		autoFocus
																	/>
																	<div className="flex items-center space-x-2 mt-2">
																		<label className="flex items-center space-x-1 text-sm text-gray-600">
																			<input 
																				type="checkbox" 
																				defaultChecked={question.is_required}
																				onChange={(e) => {
																					handleUpdateQuestion(section.id, question.id, { is_required: e.target.checked });
																				}}
																				className="rounded text-purple-600 focus:ring-purple-500"
																			/>
																			<span>Required</span>
																		</label>
																	</div>
																</div>
															) : (
																<p 
																	className="text-gray-800 mb-3 cursor-pointer hover:text-purple-600 transition-colors" 
																	onClick={() => handleEditQuestion(section.id, question.id)}
																>
																	{question.text}
																</p>
															)}
															
															{/* Interactive Question Preview */}
															{question.type === "AssessmentQuestions::MultipleChoice" && (
																<div className="space-y-2">
																	{question.options.map((option: any, optIndex: number) => (
																		<label key={optIndex} className="flex items-center space-x-2 cursor-pointer group">
																			<input 
																				type="checkbox" 
																				className="rounded text-purple-600 focus:ring-purple-500"
																				onChange={() => {
																					setHasUnsavedChanges(true);
																					setShowSaveBar(true);
																				}}
																			/>
																			<div className="flex items-center space-x-2 flex-1">
																				{editingOption?.questionId === question.id && editingOption?.optionIndex === optIndex ? (
																					<input 
																						type="text"
																						defaultValue={option.text}
																						className="text-sm flex-1 px-2 py-1 border border-purple-300 rounded"
																						onKeyDown={(e) => {
																							if (e.key === 'Enter') {
																								handleUpdateOption(section.id, question.id, optIndex, (e.target as HTMLInputElement).value);
																							} else if (e.key === 'Escape') {
																								setEditingOption(null);
																							}
																						}}
																						onBlur={(e) => {
																							handleUpdateOption(section.id, question.id, optIndex, e.target.value);
																						}}
																						autoFocus
																					/>
																				) : (
																					<span className="text-sm text-gray-700 flex-1">
																						{option.text}
																					</span>
																				)}
																				<button 
																					onClick={() => handleEditOption(question.id, optIndex)}
																					className="p-1 rounded hover:bg-gray-200 transition-colors opacity-0 group-hover:opacity-100"
																					title="Edit option"
																				>
																					<Edit className="w-3 h-3 text-gray-500" />
																				</button>
																			</div>
																		</label>
																	))}
																</div>
															)}
															
															{question.type === "AssessmentQuestions::Radio" && (
																<div className="space-y-2">
																	{question.options.map((option: any, optIndex: number) => (
																		<label key={optIndex} className="flex items-center space-x-2 cursor-pointer group">
																			<input 
																				type="radio" 
																				name={`preview-${question.id}`} 
																				className="text-purple-600 focus:ring-purple-500"
																				onChange={() => {
																					setHasUnsavedChanges(true);
																					setShowSaveBar(true);
																				}}
																			/>
																			<div className="flex items-center space-x-2 flex-1">
																				{editingOption?.questionId === question.id && editingOption?.optionIndex === optIndex ? (
																					<input 
																						type="text"
																						defaultValue={option.text}
																						className="text-sm flex-1 px-2 py-1 border border-purple-300 rounded"
																						onKeyDown={(e) => {
																							if (e.key === 'Enter') {
																								handleUpdateOption(section.id, question.id, optIndex, (e.target as HTMLInputElement).value);
																							} else if (e.key === 'Escape') {
																								setEditingOption(null);
																							}
																						}}
																						onBlur={(e) => {
																							handleUpdateOption(section.id, question.id, optIndex, e.target.value);
																						}}
																						autoFocus
																					/>
																				) : (
																					<span className="text-sm text-gray-700 flex-1">
																						{option.text}
																					</span>
																				)}
																				<button 
																					onClick={() => handleEditOption(question.id, optIndex)}
																					className="p-1 rounded hover:bg-gray-200 transition-colors opacity-0 group-hover:opacity-100"
																					title="Edit option"
																				>
																					<Edit className="w-3 h-3 text-gray-500" />
																				</button>
																			</div>
																		</label>
																	))}
																</div>
															)}
															
															{question.type === "AssessmentQuestions::RangeType" && (
																<div className="space-y-2">
																	<input 
																		type="range" 
																		min={question.meta_data?.min || 1}
																		max={question.meta_data?.max || 10}
																		className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
																		onChange={() => {
																			setHasUnsavedChanges(true);
																			setShowSaveBar(true);
																		}}
																	/>
																	<div className="flex justify-between text-xs text-gray-500">
																		<span>Min: {question.meta_data?.min || 1}</span>
																		<span>Max: {question.meta_data?.max || 10}</span>
																	</div>
																</div>
															)}
															
															{question.type === "AssessmentQuestions::RichText" && (
																<textarea 
																	placeholder="Long answer text"
																	className="w-full p-3 border border-gray-200 rounded-md resize-none focus:border-purple-500 focus:ring-purple-500"
																	rows={3}
																	onChange={() => {
																		setHasUnsavedChanges(true);
																		setShowSaveBar(true);
																	}}
																/>
															)}
														</div>
														<div className="flex items-center space-x-2 ml-4">
															<button 
																onClick={() => handleEditQuestion(section.id, question.id)}
																className="p-1 rounded hover:bg-gray-200 transition-colors"
																title="Edit question"
															>
																<Edit className="w-4 h-4 text-gray-600" />
															</button>
															<button 
																onClick={() => handleToggleConditionalLogic(question.id, section.id)}
																className={`p-1 rounded transition-colors ${
																	question.is_conditional 
																		? 'bg-purple-100 text-purple-600 hover:bg-purple-200' 
																		: 'hover:bg-gray-200 text-gray-600'
																}`}
																title={question.is_conditional ? "Edit conditional logic" : "Add conditional logic"}
															>
																<GripVertical className="w-4 h-4" />
															</button>
															<button 
																onClick={() => handleDeleteQuestion(section.id, question.id)}
																className="p-1 rounded hover:bg-red-100 transition-colors"
																title="Delete question"
															>
																<Trash2 className="w-4 h-4 text-red-600" />
															</button>
														</div>
													</div>
												</div>
											))
										) : null}
										
										{/* Add Question Button */}
										{section.questions && section.questions.length > 0 ? (
											<div className="pt-4 border-t border-gray-200">
												<button 
													onClick={() => handleAddQuestion(section.id)}
													className="flex items-center px-4 py-2 text-sm font-medium text-purple-600 bg-purple-50 border border-purple-200 rounded-lg hover:bg-purple-100 transition-colors"
												>
													<Plus className="w-4 h-4 mr-2" />
													Add question
												</button>
											</div>
										) : (
											<div className="border-2 border-dashed border-gray-200 rounded-lg p-6 text-center">
												<FileText className="w-8 h-8 text-gray-400 mx-auto mb-2" />
												<p className="text-gray-500 text-sm">No questions in this section</p>
												<button 
													onClick={() => handleAddQuestion(section.id)}
													className="text-purple-600 text-sm hover:underline mt-2"
												>
													Add first question
												</button>
											</div>
										)}
									</div>
								</div>
							</Card>
						))}

						{/* Add Section Button with Popover */}
						<div className="text-center relative" ref={sectionPopoverRef}>
							<button 
								onClick={() => setShowSectionTypes(!showSectionTypes)}
								className={`flex items-center px-6 py-3 text-sm font-medium transition-all mx-auto shadow-sm rounded-lg ${
									showSectionTypes 
										? 'text-purple-700 bg-purple-50 border-2 border-purple-400'
										: 'text-gray-700 bg-white border-2 border-dashed border-gray-300 hover:border-purple-400 hover:text-purple-600'
								}`}
							>
								<Plus className="w-5 h-5 mr-2" />
								Add Section
							</button>

							{/* Section Types Popover */}
							{showSectionTypes && (
								<div className="absolute top-full left-1/2 transform -translate-x-1/2 mt-2 z-50">
									<div className="bg-white rounded-lg shadow-xl border border-gray-200 p-4 min-w-[400px]">
										{/* Popover Arrow */}
										<div className="absolute -top-2 left-1/2 transform -translate-x-1/2">
											<div className="w-4 h-4 bg-white border-l border-t border-gray-200 transform rotate-45"></div>
										</div>
										
										{/* Header */}
										<div className="flex items-center justify-between mb-4">
											<h3 className="text-lg font-semibold text-gray-900">Choose section type</h3>
											<button 
												onClick={() => setShowSectionTypes(false)}
												className="p-1 rounded-md hover:bg-gray-100 transition-colors"
											>
												<X className="w-4 h-4 text-gray-500" />
											</button>
										</div>

										{/* Section Type Grid */}
										<div className="grid grid-cols-1 gap-2 max-h-80 overflow-y-auto">
											{sectionTypes.map((type) => {
												const Icon = type.icon;
												return (
													<button
														key={type.id}
														onClick={() => handleAddSection(type)}
														className="p-3 rounded-lg border border-gray-200 hover:border-purple-300 hover:bg-purple-50 transition-all text-left group w-full"
													>
														<div className="flex items-center space-x-3">
															<div className={`w-10 h-10 rounded-lg flex items-center justify-center ${type.bgColor} group-hover:scale-105 transition-transform`}>
																<Icon className={`w-5 h-5 ${type.color}`} />
															</div>
															<div className="flex-1">
																<p className="font-medium text-gray-900">{type.name}</p>
																<p className="text-xs text-gray-500">{type.description}</p>
															</div>
														</div>
													</button>
												);
											})}
										</div>
									</div>
								</div>
							)}
						</div>

						{/* Question Types Selector */}
						{showQuestionTypes && (
							<div className="fixed inset-0 bg-black bg-opacity-5 flex items-center justify-center z-50">
								<Card className="max-w-2xl w-full m-4 border border-purple-300 shadow-xl">
									<div className="p-6">
										<div className="flex items-center justify-between mb-4">
											<h3 className="text-lg font-semibold text-gray-900">Choose question type</h3>
											<button 
												onClick={() => setShowQuestionTypes(null)}
												className="text-gray-400 hover:text-gray-600 transition-colors"
											>
												<X className="w-5 h-5" />
											</button>
										</div>
										<div className="grid grid-cols-2 md:grid-cols-3 gap-4">
											{availableQuestionTypes.map((type) => {
												const Icon = type.icon;
												return (
													<button
														key={type.type}
														onClick={() => handleCreateQuestion(showQuestionTypes.sectionId, type.type)}
														className="p-4 rounded-lg border border-gray-200 hover:border-purple-300 hover:shadow-sm transition-all text-left group"
													>
														<div className="flex items-center space-x-3">
															<div className={`w-10 h-10 rounded-lg flex items-center justify-center ${type.bgColor} group-hover:scale-105 transition-transform`}>
																<Icon className={`w-5 h-5 ${type.color}`} />
															</div>
															<div>
																<p className="font-medium text-gray-900">{type.name}</p>
																<p className="text-xs text-gray-500">{type.description}</p>
															</div>
														</div>
													</button>
												);
											})}
										</div>
									</div>
								</Card>
							</div>
						)}

						{/* Conditional Logic Modal */}
						{showConditionalLogic && (
							<div className="fixed inset-0 bg-black bg-opacity-5 flex items-center justify-center z-50">
								<Card className="max-w-3xl w-full m-4 border border-purple-300 shadow-xl">
									<div className="p-6">
										<div className="flex items-center justify-between mb-6">
											<h3 className="text-lg font-semibold text-gray-900">Conditional Logic</h3>
											<button 
												onClick={() => setShowConditionalLogic(null)}
												className="text-gray-400 hover:text-gray-600 transition-colors"
											>
												<X className="w-5 h-5" />
											</button>
										</div>
										
										{/* Conditional Logic Form */}
										<div className="space-y-4">
											<div className="flex items-center space-x-3">
												<input 
													type="checkbox" 
													id="enable-conditional"
													className="rounded text-purple-600 focus:ring-purple-500"
													defaultChecked={
														sections
															.find(s => s.id === showConditionalLogic?.sectionId)
															?.questions.find(q => q.id === showConditionalLogic?.questionId)
															?.is_conditional || false
													}
												/>
												<label htmlFor="enable-conditional" className="text-sm font-medium text-gray-700">
													Only show this question based on a previous answer
												</label>
											</div>

											<div className="bg-gray-50 p-4 rounded-lg space-y-4">
												<div className="grid grid-cols-2 gap-4">
													<div>
														<label className="block text-sm font-medium text-gray-700 mb-2">
															Show this question when:
														</label>
														<select className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500">
															<option value="">Select a previous question...</option>
															{sections.flatMap(section => 
																section.questions
																	.filter(q => q.order < (
																		sections
																			.find(s => s.id === showConditionalLogic?.sectionId)
																			?.questions.find(qu => qu.id === showConditionalLogic?.questionId)
																			?.order || 999
																	))
																	.map(q => (
																		<option key={q.id} value={q.id}>
																			{section.name} - {q.text.substring(0, 50)}...
																		</option>
																	))
															)}
														</select>
													</div>
													<div>
														<label className="block text-sm font-medium text-gray-700 mb-2">
															Response type:
														</label>
														<select className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500">
															<option value="option_selected">Option is selected</option>
															<option value="value_equals">Value equals</option>
															<option value="value_range">Value in range</option>
														</select>
													</div>
												</div>

												<div className="grid grid-cols-2 gap-4">
													<div>
														<label className="block text-sm font-medium text-gray-700 mb-2">
															Trigger values:
														</label>
														<input 
															type="text"
															placeholder="Enter values separated by commas"
															className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500"
														/>
														<p className="text-xs text-gray-500 mt-1">
															For options, use option IDs. For text, use exact values.
														</p>
													</div>
													<div>
														<label className="block text-sm font-medium text-gray-700 mb-2">
															Comparison:
														</label>
														<select className="w-full p-2 border border-gray-300 rounded-md focus:border-purple-500 focus:ring-purple-500">
															<option value="contains">Contains any</option>
															<option value="equals">Equals exactly</option>
															<option value="not_equals">Does not equal</option>
															<option value="all">Contains all</option>
															<option value="none">Contains none</option>
															<option value="greater_than">Greater than</option>
															<option value="less_than">Less than</option>
															<option value="between">Between range</option>
														</select>
													</div>
												</div>

												<div className="bg-blue-50 p-3 rounded border border-blue-200">
													<p className="text-sm text-blue-800">
														<strong>Preview:</strong> This question will be shown when the selected question's response matches your criteria.
													</p>
												</div>
											</div>

											<div className="flex items-center justify-end space-x-3 pt-4 border-t border-gray-200">
												<button 
													onClick={() => setShowConditionalLogic(null)}
													className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
												>
													Cancel
												</button>
												<button 
													onClick={() => {
														// For now, just close the modal - we'd implement the actual save logic here
														setShowConditionalLogic(null);
														setHasUnsavedChanges(true);
														setShowSaveBar(true);
													}}
													className="px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700 transition-colors"
												>
													Save Logic
												</button>
											</div>
										</div>
									</div>
								</Card>
							</div>
						)}

						{error && (
							<Alert color="failure" icon={AlertCircle}>
								{error}
							</Alert>
						)}
					</div>
				</div>
			</DashboardLayout.Content>
		</DashboardLayout>
	);
}

export const routePath = {
	path: "/app/assessments/:id/sections",
	Component: AssessmentSections,
} as RouteObject;