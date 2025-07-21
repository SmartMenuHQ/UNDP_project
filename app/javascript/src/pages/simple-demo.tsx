import { Button, Card, Badge, Alert } from "flowbite-react";
import { RouteObject } from "react-router";

export default function SimpleDemo() {
	return (
		<div className="min-h-screen bg-gray-50 p-8">
			<div className="max-w-4xl mx-auto space-y-8">
				{/* Header */}
				<div className="text-center">
					<h1 className="text-4xl font-bold text-gray-900 mb-4">Flowbite is Ready! ✨</h1>
					<p className="text-xl text-gray-600">
						Your Questionnaire CMS now has beautiful UI components
					</p>
				</div>

				{/* Success Alert */}
				<Alert color="success">
					<span className="font-medium">Success!</span> Flowbite has been successfully
					integrated into your Rails application.
				</Alert>

				{/* Feature Cards */}
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
					<Card>
						<h5 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
							Create Assessments
						</h5>
						<p className="font-normal text-gray-700 dark:text-gray-400">
							Build interactive questionnaires with 7 different question types.
						</p>
						<Button>Get Started</Button>
					</Card>

					<Card>
						<h5 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
							Manage Responses
						</h5>
						<p className="font-normal text-gray-700 dark:text-gray-400">
							Collect and analyze responses from your participants.
						</p>
						<Button color="green">View Responses</Button>
					</Card>

					<Card>
						<h5 className="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
							Multi-language Support
						</h5>
						<p className="font-normal text-gray-700 dark:text-gray-400">
							Automatically translate assessments with AI-powered tools.
						</p>
						<Button color="purple">Translate</Button>
					</Card>
				</div>

				{/* Status Badges */}
				<div className="bg-white p-6 rounded-lg shadow">
					<h3 className="text-lg font-semibold text-gray-900 mb-4">
						Assessment Status Examples
					</h3>
					<div className="flex gap-3 flex-wrap">
						<Badge color="green">Active</Badge>
						<Badge color="yellow">Draft</Badge>
						<Badge color="blue">Published</Badge>
						<Badge color="red">Archived</Badge>
						<Badge color="purple">Featured</Badge>
						<Badge color="gray">Inactive</Badge>
					</div>
				</div>

				{/* Action Buttons */}
				<div className="bg-white p-6 rounded-lg shadow">
					<h3 className="text-lg font-semibold text-gray-900 mb-4">Available Actions</h3>
					<div className="flex gap-4 flex-wrap">
						<Button color="blue">Create New Assessment</Button>
						<Button color="gray">View All Assessments</Button>
						<Button color="green">Export Data</Button>
						<Button color="red">Delete Selected</Button>
						<Button outline>Configure Settings</Button>
					</div>
				</div>

				{/* Stats Section */}
				<div className="grid grid-cols-1 md:grid-cols-4 gap-4">
					<div className="bg-blue-50 p-6 rounded-lg text-center">
						<div className="text-3xl font-bold text-blue-600">24</div>
						<div className="text-gray-600">Total Assessments</div>
					</div>
					<div className="bg-green-50 p-6 rounded-lg text-center">
						<div className="text-3xl font-bold text-green-600">1,247</div>
						<div className="text-gray-600">Total Responses</div>
					</div>
					<div className="bg-purple-50 p-6 rounded-lg text-center">
						<div className="text-3xl font-bold text-purple-600">5</div>
						<div className="text-gray-600">Languages</div>
					</div>
					<div className="bg-yellow-50 p-6 rounded-lg text-center">
						<div className="text-3xl font-bold text-yellow-600">89%</div>
						<div className="text-gray-600">Completion Rate</div>
					</div>
				</div>

				{/* Footer */}
				<div className="text-center py-8">
					<Card>
						<h3 className="text-xl font-semibold text-gray-900 mb-2">
							🚀 Ready to Build Amazing Questionnaires?
						</h3>
						<p className="text-gray-600 mb-4">
							You now have Flowbite integrated with your Rails application. Start building
							beautiful interfaces for your questionnaire management system.
						</p>
						<div className="flex gap-4 justify-center">
							<Button color="blue" size="lg">
								Start Creating
							</Button>
							<Button color="gray" size="lg">
								View Documentation
							</Button>
						</div>
					</Card>
				</div>
			</div>
		</div>
	);
}

export const routePath = {
	path: "/app/simple-demo",
	Component: SimpleDemo,
} as RouteObject;
