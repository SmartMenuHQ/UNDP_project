"use client";

import { useState } from "react";
import { Modal, Label, TextInput, Alert } from "flowbite-react";
import { 
	FileText, 
	CheckSquare, 
	Circle, 
	ToggleLeft, 
	Calendar, 
	Sliders, 
	Upload,
	Plus
} from "lucide-react";

interface SectionType {
	id: string;
	name: string;
	description: string;
	iconName: string;
	color: string;
	bgColor: string;
	borderColor: string;
}

const sectionTypes: SectionType[] = [
	{
		id: "basic",
		name: "Basic Information",
		description: "Simple text questions and basic inputs",
		iconName: "FileText",
		color: "text-blue-600",
		bgColor: "bg-blue-50",
		borderColor: "border-blue-200"
	},
	{
		id: "multiple_choice",
		name: "Multiple Choice",
		description: "Questions with multiple selectable options",
		iconName: "CheckSquare",
		color: "text-green-600",
		bgColor: "bg-green-50",
		borderColor: "border-green-200"
	},
	{
		id: "single_choice", 
		name: "Single Choice",
		description: "Radio button questions with one answer",
		iconName: "Circle",
		color: "text-purple-600",
		bgColor: "bg-purple-50",
		borderColor: "border-purple-200"
	},
	{
		id: "rating_scale",
		name: "Rating & Scales",
		description: "Sliders, ratings, and numeric ranges",
		iconName: "Sliders",
		color: "text-red-600",
		bgColor: "bg-red-50",
		borderColor: "border-red-200"
	},
	{
		id: "date_time",
		name: "Date & Time",
		description: "Date pickers and time inputs",
		iconName: "Calendar",
		color: "text-orange-600",
		bgColor: "bg-orange-50",
		borderColor: "border-orange-200"
	},
	{
		id: "file_upload",
		name: "File Upload",
		description: "Document and file upload questions",
		iconName: "Upload",
		color: "text-yellow-600",
		bgColor: "bg-yellow-50",
		borderColor: "border-yellow-200"
	}
];

const getIcon = (iconName: string) => {
	switch (iconName) {
		case "FileText": return FileText;
		case "CheckSquare": return CheckSquare;
		case "Circle": return Circle;
		case "Sliders": return Sliders;
		case "Calendar": return Calendar;
		case "Upload": return Upload;
		default: return FileText;
	}
};

interface SectionBuilderModalProps {
	isOpen: boolean;
	onClose: () => void;
	onCreateSection: (sectionType: string, sectionName: string) => Promise<void>;
	isLoading?: boolean;
}

export default function SectionBuilderModal({ 
	isOpen, 
	onClose, 
	onCreateSection, 
	isLoading = false 
}: SectionBuilderModalProps) {
	const [selectedType, setSelectedType] = useState<string>("");
	const [sectionName, setSectionName] = useState("");
	const [error, setError] = useState<string | null>(null);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		
		if (!selectedType) {
			setError("Please select a section type");
			return;
		}
		
		if (!sectionName.trim()) {
			setError("Please enter a section name");
			return;
		}

		try {
			await onCreateSection(selectedType, sectionName.trim());
			handleClose();
		} catch (err) {
			setError(err instanceof Error ? err.message : "Failed to create section");
		}
	};

	const handleClose = () => {
		setSelectedType("");
		setSectionName("");
		setError(null);
		onClose();
	};

	const selectedSectionType = sectionTypes.find(type => type.id === selectedType);

	return (
		<Modal show={isOpen} onClose={handleClose} size="4xl">
			<Modal.Header>
				<div className="flex items-center space-x-3">
					<div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
						<Plus className="w-4 h-4 text-purple-600" />
					</div>
					<span>Add New Section</span>
				</div>
			</Modal.Header>
			
			<Modal.Body>
				<form onSubmit={handleSubmit} className="space-y-6">
					{error && (
						<Alert color="failure">
							{error}
						</Alert>
					)}

					{/* Section Type Selection */}
					<div>
						<Label value="Choose Section Type" className="mb-4 block text-lg font-semibold" />
						<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
							{sectionTypes.map((type) => {
								const Icon = getIcon(type.iconName);
								const isSelected = selectedType === type.id;
								
								return (
									<div
										key={type.id}
										onClick={() => setSelectedType(type.id)}
										className={`
											p-4 rounded-lg border-2 cursor-pointer transition-all duration-200
											${isSelected 
												? `${type.borderColor} ${type.bgColor} shadow-md` 
												: 'border-gray-200 hover:border-gray-300 bg-white hover:bg-gray-50'
											}
										`}
									>
										<div className="flex items-start space-x-3">
											<div className={`w-10 h-10 rounded-lg flex items-center justify-center ${isSelected ? type.bgColor : 'bg-gray-100'}`}>
												<Icon className={`w-5 h-5 ${isSelected ? type.color : 'text-gray-600'}`} />
											</div>
											<div className="flex-1">
												<h3 className={`font-semibold ${isSelected ? type.color : 'text-gray-900'}`}>
													{type.name}
												</h3>
												<p className="text-sm text-gray-600 mt-1">
													{type.description}
												</p>
											</div>
											{isSelected && (
												<div className={`w-5 h-5 rounded-full ${type.bgColor} flex items-center justify-center`}>
													<div className={`w-2 h-2 rounded-full bg-current ${type.color}`}></div>
												</div>
											)}
										</div>
									</div>
								);
							})}
						</div>
					</div>

					{/* Section Name Input */}
					{selectedType && (
						<div className="space-y-4">
							<div>
								<Label htmlFor="sectionName" value="Section Name" className="mb-2 block" />
								<TextInput
									id="sectionName"
									type="text"
									placeholder={`Enter name for ${selectedSectionType?.name.toLowerCase()} section`}
									value={sectionName}
									onChange={(e) => setSectionName(e.target.value)}
									required
									disabled={isLoading}
									className="w-full"
								/>
							</div>
							
							{selectedSectionType && (
								<div className={`p-4 rounded-lg ${selectedSectionType.bgColor} ${selectedSectionType.borderColor} border`}>
									<div className="flex items-center space-x-3">
										{(() => {
											const Icon = getIcon(selectedSectionType.iconName);
											return <Icon className={`w-5 h-5 ${selectedSectionType.color}`} />;
										})()}
										<div>
											<h4 className={`font-medium ${selectedSectionType.color}`}>
												{selectedSectionType.name}
											</h4>
											<p className="text-sm text-gray-600">
												{selectedSectionType.description}
											</p>
										</div>
									</div>
								</div>
							)}
						</div>
					)}
				</form>
			</Modal.Body>

			<Modal.Footer>
				<div className="flex items-center justify-end space-x-3 w-full">
					<button 
						type="button"
						onClick={handleClose}
						disabled={isLoading}
						className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
					>
						Cancel
					</button>
					<button 
						type="button"
						onClick={handleSubmit}
						disabled={isLoading || !selectedType || !sectionName.trim()}
						className="px-4 py-2 text-sm font-medium text-white bg-purple-600 border border-purple-600 rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
					>
						{isLoading ? 'Creating...' : 'Create Section'}
					</button>
				</div>
			</Modal.Footer>
		</Modal>
	);
}