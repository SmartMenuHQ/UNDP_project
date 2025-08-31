"use client";

import React, { useState } from 'react';
import { Card } from 'flowbite-react';
import { 
	X, 
	FileText, 
	CheckSquare,
	Circle,
	Sliders,
	Calendar,
	Upload,
	Plus
} from 'lucide-react';

interface SectionType {
	id: string;
	name: string;
	description: string;
	icon: React.ComponentType<any>;
	color: string;
	bgColor: string;
}

interface AddQuestionModalProps {
	show: boolean;
	onClose: () => void;
	sectionId: number;
	sectionName: string;
	onCreateQuestion: (sectionId: number, questionType: string) => void;
}

const questionTypes: SectionType[] = [
	{
		id: "AssessmentQuestions::RichText",
		name: "Text",
		description: "Short answer or paragraph text",
		icon: FileText,
		color: "text-blue-600",
		bgColor: "bg-blue-50"
	},
	{
		id: "AssessmentQuestions::MultipleChoice",
		name: "Multiple choice",
		description: "Select multiple options",
		icon: CheckSquare,
		color: "text-green-600",
		bgColor: "bg-green-50"
	},
	{
		id: "AssessmentQuestions::Radio", 
		name: "Single choice",
		description: "Select one option",
		icon: Circle,
		color: "text-purple-600",
		bgColor: "bg-purple-50"
	},
	{
		id: "AssessmentQuestions::RangeType",
		name: "Linear scale",
		description: "Rating or numeric scale",
		icon: Sliders,
		color: "text-red-600",
		bgColor: "bg-red-50"
	},
	{
		id: "AssessmentQuestions::DateType",
		name: "Date",
		description: "Date and time picker",
		icon: Calendar,
		color: "text-orange-600",
		bgColor: "bg-orange-50"
	},
	{
		id: "AssessmentQuestions::FileUpload",
		name: "File upload",
		description: "Upload documents or images",
		icon: Upload,
		color: "text-yellow-600",
		bgColor: "bg-yellow-50"
	}
];

const AddQuestionModal: React.FC<AddQuestionModalProps> = ({
	show,
	onClose,
	sectionId,
	sectionName,
	onCreateQuestion
}) => {
	const [selectedType, setSelectedType] = useState<string | null>(null);

	const handleCreateQuestion = (questionType: string) => {
		onCreateQuestion(sectionId, questionType);
		onClose();
		setSelectedType(null);
	};

	if (!show) return null;

	return (
		<div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
			<Card className="max-w-3xl w-full max-h-[90vh] overflow-y-auto border border-gray-300 shadow-xl">
				<div className="p-6">
					{/* Header */}
					<div className="flex items-center justify-between mb-6">
						<div>
							<h3 className="text-xl font-semibold text-gray-900">Add Question</h3>
							<p className="text-sm text-gray-600 mt-1">Adding question to section: <span className="font-medium">{sectionName}</span></p>
						</div>
						<button
							onClick={onClose}
							className="text-gray-400 hover:text-gray-600 transition-colors p-1 rounded-md hover:bg-gray-100"
						>
							<X className="w-5 h-5" />
						</button>
					</div>

					{/* Question Types Grid */}
					<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
						{questionTypes.map((questionType) => {
							const IconComponent = questionType.icon;
							const isSelected = selectedType === questionType.id;
							
							return (
								<button
									key={questionType.id}
									onClick={() => handleCreateQuestion(questionType.id)}
									onMouseEnter={() => setSelectedType(questionType.id)}
									onMouseLeave={() => setSelectedType(null)}
									className={`p-4 rounded-lg border-2 transition-all text-left hover:shadow-md ${
										isSelected 
											? 'border-purple-400 bg-purple-50 shadow-md' 
											: 'border-gray-200 hover:border-purple-200 bg-white hover:bg-purple-25'
									}`}
								>
									<div className="flex items-start space-x-3">
										<div className={`p-2 rounded-lg ${questionType.bgColor}`}>
											<IconComponent className={`w-5 h-5 ${questionType.color}`} />
										</div>
										<div className="flex-1 min-w-0">
											<h4 className="font-medium text-gray-900 text-sm mb-1">
												{questionType.name}
											</h4>
											<p className="text-xs text-gray-600 leading-relaxed">
												{questionType.description}
											</p>
										</div>
										<div className={`transition-opacity ${isSelected ? 'opacity-100' : 'opacity-0'}`}>
											<Plus className="w-4 h-4 text-purple-600" />
										</div>
									</div>
								</button>
							);
						})}
					</div>

					{/* Footer */}
					<div className="flex items-center justify-end space-x-3 pt-6 border-t border-gray-200 mt-6">
						<button
							onClick={onClose}
							className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
						>
							Cancel
						</button>
					</div>
				</div>
			</Card>
		</div>
	);
};

export default AddQuestionModal;