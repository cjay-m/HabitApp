//
//  HabitViewModel.swift
//  HabitTracker
//
//  Created by cjay on 5/20/23.
//

import SwiftUI
import CoreData
import UserNotifications

class HabitViewModel: ObservableObject {
    // new habit properties
    
    @Published var addNewHabit: Bool = false
    
    @Published var title: String = ""
    @Published var habitColor: String = "Card-1"
    @Published var weekDays: [String] = []
    @Published var isReminderOn: Bool = false
    @Published var reminderText: String = ""
    @Published var reminderDate: Date = Date()
    
    // remainder time
    @Published var showTimePicker: Bool = false
    
    // editing habit
    @Published var editHabit: Habit?
    
    // Mnotification access
    @Published var notificationAccess: Bool = false
    
    init(){
        requestNotificationAccess()
    }
    
    func requestNotificationAccess(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound,.alert]) { status, _ in
            DispatchQueue.main.async {
                self.notificationAccess = status
            }
        }
    }
    
    // adding the habit to database
    func addHabbit(context: NSManagedObjectContext)async->Bool{
        // edit the data
        var habit: Habit!
        if let editHabit = editHabit {
            habit = editHabit
            // Removing All Pending Notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: editHabit.notificationIDs ?? [])
        }else{
            habit = Habit(context: context)
        }
        habit.name = title
        habit.color = habitColor
        habit.weekDays = weekDays
        habit.isReminderOn = isReminderOn
        habit.reminderText = reminderText
        habit.notificationDate = reminderDate
        habit.dateAdded = Date()
        habit.notificationIDs = []
        
        if isReminderOn{
            // schedule the notifications
            if let ids = try? await scheduleNotification(){
                habit.notificationIDs = ids
                if let _ = try? context.save(){
                    return true
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            }
        }else{
            // add data
            if let _ = try? context.save(){
                return true
            }
        }
      return false
    }
    
    // adding the notifications
    func scheduleNotification()async throws->[String]{
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.subtitle = reminderText
        content.sound = UNNotificationSound.default
        
        // Scheduled Ids
        var notificationIDs: [String] = []
        let calendar = Calendar.current
        let weekdaySymbols: [String] = calendar.weekdaySymbols
        
        // scheduling the notification
        
        for weekDay in weekDays {
            // id for each of the individual notifications
            let id = UUID().uuidString
            let hour = calendar.component(.hour, from: reminderDate)
            let min = calendar.component(.minute, from: reminderDate)
            let day = weekdaySymbols.firstIndex { currentDay in
                return currentDay == weekDay
            } ?? -1
            
            // neccessary to add +1 to index due to the way that the weeks work
            
            if day != -1{
                var components = DateComponents()
                components.hour = hour
                components.minute = min
                components.weekday = day + 1
            
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                // MARK: Notification Request
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                // ADDING ID
                notificationIDs.append(id)
                
                try await UNUserNotificationCenter.current().add(request)
            }
        }
        
        return notificationIDs
    }
    
    // reset all the data, erase content
    func resetData(){
        title = ""
        habitColor = "Card-1"
        weekDays = []
        isReminderOn = false
        reminderDate = Date()
        reminderText = ""
        editHabit = nil
    }
    
    // delete the habit from the database
    func deleteHabit(context: NSManagedObjectContext)->Bool{
        if let editHabit = editHabit {
            if editHabit.isReminderOn{
                // Removing All Pending Notifications
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: editHabit.notificationIDs ?? [])
            }
            context.delete(editHabit)
            if let _ = try? context.save(){
                return true
            }
        }
        
        return false
    }
    
    // edit the data
    func restoreEditData(){
        if let editHabit = editHabit {
            title = editHabit.name ?? ""
            habitColor = editHabit.color ?? "Card-1"
            weekDays = editHabit.weekDays ?? []
            isReminderOn = editHabit.isReminderOn
            reminderDate = editHabit.notificationDate ?? Date()
            reminderText = editHabit.reminderText ?? ""
        }
    }
    
    // Done button
    func doneStatus()->Bool{
        let remainderStatus = isReminderOn ? reminderText == "" : false
        
        if title == "" || weekDays.isEmpty || remainderStatus{
            return false
        }
        return true
    }
}
