import { UserTable } from '@/features/users/components/UserTable';

export default function UsersPage() {
    return (
        <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold tracking-tight">User Management</h1>
            </div>
            <UserTable />
        </div>
    );
}
