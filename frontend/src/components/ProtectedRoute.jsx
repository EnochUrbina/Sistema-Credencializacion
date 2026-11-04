export default function ProtectedRoute({user,children,fallback}){return user?children:fallback;}
