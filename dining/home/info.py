import tkinter as tk
import tkinter.font as tkFont

def create_window():
    root = tk.Tk()

    #Set the geometry
    root.geometry("1920x100+0+1100")

    font = tkFont.Font(size=48, weight="bold")

    #Create a Label
    label = tk.Label(root, text="Zaterdag, 23 november 2024   18:42   20°C", font=font)
    label.pack()

    #Make the window borderless
    root.overrideredirect(True)

    root.mainloop()

create_window()
