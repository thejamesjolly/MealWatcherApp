/**
 <MealWatcher is a phone & watch application to record motion data from a watch and smart ring>
 Copyright (C) <2023>  <James Jolly, Faria Armin, Adam Hoover>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
  File: EMAQuestions.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 7/7/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Create survey taken in the phone app after each meal.
*/

import Foundation
import SwiftUI
import Combine

func TrueFalseQuestion( _ title : String ) -> MultipleChoiceQuestion {
    return MultipleChoiceQuestion(title: title, answers: [ "Definitely false" , "Mostly False", "Mostly true", "Definitely true" ], tag: TitleToTag(title))
}

let EMAQuestions = Survey([
        
    MCQ(title: "This survey is for what meal/snack?",
                                          items: [
                                            "The meal I just finished",
                                            MultipleChoiceResponse("A meal/snack earlier today or yesterday (please provide time)", allowsCustomTextEntry: true)                                          ], multiSelect: false,
                                          tag: "meal-time"),
    
    vegetable_servings,
    
    fruit_servings,
        
    MCQ(title: "Did you eat any of the following during this meal or snack?",
                                          items: [
                                            "Oil/Butter/Salad Dressing",
                                            "Cheese",
                                            "Chips or other Salty Snacks",
                                            "Beef/Pork",
                                            "Bacon",
                                            "Hot Dogs/Lunch Meat",
                                            "Hot Dogs",
                                            "Fried Food",
                                            
                                            "None of these categories apply"
                                          ], multiSelect: true,
                                          tag: "high-fat-items"),
    
    MCQ(title: "Did you eat any of the following during this meal or snack?",
                                          items: [
                                            "Sugar or honey (include any added to your drinks)",
                                            "Chocolate or other types of candy",
                                            "Sweets (like donuts, cake, cookies, pie, brownies)",
                                            "Ice cream or other frozen desserts",
                                            "None of these categories apply"
                                          ], multiSelect: true,
                                          tag: "high-sugar-items"),
    
    MCQ(title: "Please select all of the following types of beverages that were consumed during this meal or snack:",
                                          items: [
                                            "Water",
                                            "Other Calorie-free beverage (e.g., diet soda, tea, black coffee)",
                                            "Caloric beverage (e.g. regular soda, juice, milk, coffee with cream)",
                                            "Alcohol (e.g. beer, wine, cocktail)",
                                            "None",
                                          ], multiSelect: true,
                                          tag: "beverage-types"),
    
    
    MCQ(title: "Please select all utensils that were used during this meal or snack:",
                                          items: [
                                            "Fork",
                                            "Knife",
                                            "Spoon",
                                            "Single hand",
                                            "Both hand",
                                            "Chopsticks",
                                            "Other"
                                          ], multiSelect: true,
                                          tag: "utensil-types"),
    
    
    MCQ(title: "Where did you get the food for this meal or snack from? Select all that apply.",
                                          items: [
                                            "Grocery Store",
                                            "Fast food Restaurant",
                                            "Restaurant/Bar",
                                            "Convenience/Corner store",
                                            "Farmer's Market",
                                            "Food pantry",
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: true,
                                          tag: "food-source"),
    
    MCQ(title: "Who prepared your food for this meal/snack? Select all that apply.",
                                          items: [
                                            "Made for myself",
                                            "By someone in my household",
                                            "By an acquaintance",
                                            "At a restaurant",
                                            "Unknown",
                                          ], multiSelect: true,
                                          tag: "food-preperation"),
    
    MCQ(title: "Where did you eat this meal or snack?",
                                          items: [
                                            "Home",
                                            "Work/School",
                                            "Friend/Family's House",
                                            "Restaurant/Cafe",
                                            "'On the go' (car, walking, commuting)",
                                            "Outside (park, hike, etc)",
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: false,
                                          tag: "meal-location"),
    
    MCQ(title: "Were you doing anything else while eating? Select all that apply.",
                                          items: [
                                            "No, just eating",
                                            "Talking with another person",
                                            "Watching TV or media",
                                            "Working or doing chores",
                                            "Walking or Driving",
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: true,
                                          tag: "activity-during-meal"),
    

    
    
    MCQ(title: "Select all statements that apply to you. During this meal or snack, I...",
                                          items: [
                                            "Was restricting my eating in order to control their weight",
                                            "Felt like I couldn't stop eating, even if I wanted to",
                                            "Ate much more quickly than usual",
                                            "Felt guilty about what or how much I ate",
                                            "None of these statements apply to me"
                                          ], multiSelect: true,
                                          tag: "eating-related-habits"),
    
    MCQ(title: "Select all statements that apply to you. During this meal or snack, I...",
                                          items: [
                                            "Felt physically hungry (i.e., empty stomach)",
                                            "Had a craving for a food I especially like",
                                            "Did not feel physically hungry but still wanted to eat",
                                            "None of these statements apply to me"
                                          ], multiSelect: true,
                                          tag: "hunger-level"),
    
    MCQ(title: "Did anything go wrong with the devices during this meal/snack? If so, Please describe what happened. Select all that apply.",
                                          items: [
                                            "No, all worked well",
                                            MultipleChoiceResponse("Ring failed", allowsCustomTextEntry: true),
                                            MultipleChoiceResponse("Watch failed", allowsCustomTextEntry: true),
                                            MultipleChoiceResponse("Phone app crashed", allowsCustomTextEntry: true),
                                            MultipleChoiceResponse("I did not wear the device(s). Please explain why:", allowsCustomTextEntry: true),
                                            MultipleChoiceResponse("Other", allowsCustomTextEntry: true)
                                          ], multiSelect: true,
                                          tag: "device-compliance"),
    
    
],
//version: "001")
//version: "002") //updated JPJ on Feb 11, 2024
//version: "003") //updated JPJ on Apr 8, 2024
//version: "004") //updated JPJ on Apr 8, 2024
version: "005") //updated JPJ on F 28, 2025

let vegetable_servings = CommentsFormQuestion(title: "How many servings of vegetables (not including potatoes) did you eat?",
                                         subtitle: "1 serving = 1/2 cup or half of a fistful",
                                         tag: "vegetable-serving-size")

let fruit_servings = CommentsFormQuestion(title: "How many servings of fruit did you eat?",
                                         subtitle: "1 serving = 1/2 cup or half of a fistful",
                                         tag: "fruit-serving-size")

#if true // If using text input
    let start_time = CommentsFormQuestion(title: "When did you start eating?",
                                         subtitle: "Give a time like 8:30PM",
                                         tag: "meal-start-time")
#else //If using Time wheel input
let start_time = TimeInputQuestion(title: "When did you start eating?",
                                     subtitle: "Give a time like 8:30PM",
                                     tag: "meal-start-time")
#endif


