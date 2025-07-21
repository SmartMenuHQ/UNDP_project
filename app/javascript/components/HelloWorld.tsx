interface HelloWorldProps {
  name?: string
  className?: string
}

const HelloWorld = ({ name = 'World', className = '' }: HelloWorldProps) => {
  const handleClick = () => {
    alert(`Hello from ${name}! 🎉`)
  }

  return (
    <>
      <div className={`p-6 bg-white rounded-lg shadow-md max-w-md mx-auto ${className}`}>
        <h2 className="text-2xl font-bold text-blue-600 mb-4">
          Hello, {name}! 👋
        </h2>
        <p className="text-gray-700 mb-4">
          This is a React component written in TypeScript JSX,
          running in your Rails application with Vite!
        </p>
        <button
          onClick={handleClick}
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition-colors duration-200"
        >
          Click me!
        </button>
        <div className="mt-4 text-sm text-gray-500">
          <p>✅ React + TypeScript</p>
          <p>✅ Rails + Vite</p>
          <p>✅ Tailwind CSS</p>
        </div>
      </div>
    </>
  )
}

export default HelloWorld
