import React from "react";
import { RouteObject } from "react-router";
import { Link } from "react-router"; // Optional if using React Router

const NotFoundPage = () => {
	return (
		<section className="h-screen justify-center flex items-center">
			<div className="py-8 px-4 mx-auto max-w-screen-xl lg:py-16 lg:px-6">
				<div className="mx-auto max-w-screen-sm text-center">
					<img
						className="mb-4 mx-auto"
						src="https://flowbite.s3.amazonaws.com/blocks/marketing-ui/404/404-computer.svg"
						alt="404 Not Found"
					></img>
					<h1 className="mb-4 text-7xl font-display tracking-tight font-extrabold lg:text-[10rem] text-primary-600">
						404
					</h1>
					<p className="mb-4 text-3xl font-display tracking-tight font-bold text-gray-900 md:text-4xl dark:text-white">
						Something's missing.
					</p>
					<p className="mb-4 text-lg text-gray-500 dark:text-gray-400">
						Sorry, we can't find that page. You'll find lots to explore on the homepage.
					</p>
					<Link
						to="/app"
						className="inline-flex text-white bg-primary-600 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:focus:ring-primary-900 my-4"
					>
						Back to Homepage
					</Link>
				</div>
			</div>
		</section>
	);
};

export default NotFoundPage;

export const routePath = {
	path: "/app/*",
	skip: true,
	Component: NotFoundPage,
} as RouteObject;
