export function getAccentColor(): number | null;
export function requestBackground(autoStart: boolean, commandLine: string[]): boolean;
export function updateUnityLauncherCount(count: number): boolean;

export interface MenuItem {
    id: number;
    label?: string;
    enabled?: boolean;
    visible?: boolean;
    type?: "separator";
}

export function initStatusNotifierItem(appName: string): boolean;
export function setStatusNotifierIcon(icon: Buffer): boolean;
export function setStatusNotifierTitle(title: string): boolean;
export function setStatusNotifierStatus(status: string): boolean;
export function setStatusNotifierIconName(iconName: string): boolean;
export function setStatusNotifierAttentionIconName(iconName: string): boolean;
export function setStatusNotifierMenu(menu: MenuItem[]): boolean;
export function updateStatusNotifierMenuItem(id: number, label: string): boolean;
export function setStatusNotifierMenuClickCallback(callback: (id: number) => void): boolean;
export function setStatusNotifierActivateCallback(callback: () => void): boolean;
export function destroyStatusNotifierItem(): void;
