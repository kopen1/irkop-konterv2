import './globals.css';
import { AppShell } from '../components/app-shell';
export const metadata={title:'IRKOP CELL — Dashboard & Kasir',description:'Frontend dashboard kasir IRKOP CELL'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="id"><body><AppShell>{children}</AppShell></body></html>}
