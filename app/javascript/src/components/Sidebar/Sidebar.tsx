import { Box } from "@radix-ui/themes";
import { PropsWithChildren } from "react";

const Sidebar = ({ children }: PropsWithChildren) => {
	return <Box>{children}</Box>;
};

export default Sidebar;
