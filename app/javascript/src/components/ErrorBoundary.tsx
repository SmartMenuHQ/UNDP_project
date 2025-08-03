import React, { Component, ErrorInfo, ReactNode } from "react";

type Props = {
	children: ReactNode;
};

type State = {
	hasError: boolean;
};

class ErrorBoundary extends Component<Props, State> {
	state: State = {
		hasError: false,
	};

	static getDerivedStateFromError(_: Error): State {
		return { hasError: true };
	}

	componentDidCatch(error: Error, info: ErrorInfo) {
		console.error("Error caught in boundary:", error, info);
	}

	render() {
		if (this.state.hasError) {
			return (
				<div className="text-center mt-20">
					<h1 className="text-4xl text-red-600 font-bold">500 - Something broke</h1>
					<p className="mt-4">Try refreshing the page or come back later.</p>
				</div>
			);
		}

		return this.props.children;
	}
}

export default ErrorBoundary;
