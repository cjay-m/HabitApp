//
//  AddNewHabit.swift
//  HabitTracker
//
//  Created by cjay on 5/20/23.
//

import SwiftUI

struct AddNewHabit: View {
    @EnvironmentObject var habitModel: HabitViewModel
    // environment value
    @Environment(\.self) var env
    var body: some View {
        NavigationView{
            VStack(spacing: 15){
                TextField("Title", text: $habitModel.title)
                    .padding(.horizontal)
                    .padding(.vertical,10)
                    .background(Color("TFBG").opacity(0.4),in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                // pick a color for the habit
                HStack(spacing: 0){
                    ForEach(1...7,id: \.self){index in
                        let color = "Card-\(index)"
                        Circle()
                            .fill(Color(color))
                            .frame(width: 30, height: 30)
                            .overlay(content: {
                                if color == habitModel.habitColor{
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            })
                            .onTapGesture {
                                withAnimation{
                                    habitModel.habitColor = color
                                }
                            }
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // frequency selection, how often
                VStack(alignment: .leading, spacing: 6) {
                    Text("Frequency")
                        .font(.callout.bold())
                    let weekDays = Calendar.current.weekdaySymbols
                    HStack(spacing: 10){
                        ForEach(weekDays,id: \.self){day in
                            let index = habitModel.weekDays.firstIndex { value in
                                return value == day
                            } ?? -1
                           
                            Text(day.prefix(2))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical,12)
                                .foregroundColor(index != -1 ? .white : .primary)
                                .background{
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(index != -1 ? Color(habitModel.habitColor) : Color("TFBG").opacity(0.4))
                                }
                                .onTapGesture {
                                    withAnimation{
                                        if index != -1{
                                            habitModel.weekDays.remove(at: index)
                                        }else{
                                            habitModel.weekDays.append(day)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.top,15)
                }
                
                Divider()
                    .padding(.vertical,10)
                
                // Hiding If Notification Access is Rejected
                HStack{
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reminder")
                            .fontWeight(.semibold)
                        
                        Text("Just notification")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    
                    Toggle(isOn: $habitModel.isReminderOn) {}
                        .labelsHidden()
                }
                .opacity(habitModel.notificationAccess ? 1 : 0)
                
                HStack(spacing: 12){
                    Label {
                        Text(habitModel.reminderDate.formatted(date: .omitted, time: .shortened))
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .padding(.horizontal)
                    .padding(.vertical,12)
                    .background(Color("TFBG").opacity(0.4),in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .onTapGesture {
                        withAnimation{
                            habitModel.showTimePicker.toggle()
                        }
                    }
                    
                    TextField("Reminder Text", text: $habitModel.reminderText)
                        .padding(.horizontal)
                        .padding(.vertical,10)
                        .background(Color("TFBG").opacity(0.4),in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .frame(height: habitModel.isReminderOn ? nil : 0)
                .opacity(habitModel.isReminderOn ? 1 : 0)
                .opacity(habitModel.notificationAccess ? 1 : 0)
            }
            .animation(.easeInOut, value: habitModel.isReminderOn)
            .frame(maxHeight: .infinity,alignment: .top)
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(habitModel.editHabit != nil ? "Edit Habit" : "Add Habit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        env.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .tint(.primary)
                }
                
                // delete button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if habitModel.deleteHabit(context: env.managedObjectContext){
                            env.dismiss()
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                    .opacity(habitModel.editHabit == nil ? 0 : 1)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done"){
                        Task{
                            if await habitModel.addHabbit(context: env.managedObjectContext){
                                env.dismiss()
                            }
                        }
                    }
                    .tint(.primary)
                    .disabled(!habitModel.doneStatus())
                    .opacity(habitModel.doneStatus() ? 1 : 0.6)
                }
            }
        }
        .overlay {
            if habitModel.showTimePicker{
                ZStack{
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation{
                                habitModel.showTimePicker.toggle()
                            }
                        }
                    
                    DatePicker.init("", selection: $habitModel.reminderDate,displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                        .background{
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("TFBG"))
                        }
                        .padding()
                }
            }
        }
    }
}

struct AddNewHabit_Previews: PreviewProvider {
    static var previews: some View {
        AddNewHabit()
            .environmentObject(HabitViewModel())
            .preferredColorScheme(.dark)
    }
}
