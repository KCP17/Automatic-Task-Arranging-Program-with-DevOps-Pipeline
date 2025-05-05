import sklearn
from sklearn.tree import DecisionTreeClassifier
import sys
class Classification:
    def __init__(self, description_arranged, type_arranged, deadline_arranged, importance_arranged, difficulty_arranged, rating, checkbox, is_checked):
        self.description_arranged = description_arranged
        self.type_arranged = type_arranged
        self.deadline_arranged = deadline_arranged
        self.importance_arranged = importance_arranged
        self.difficulty_arranged = difficulty_arranged
        self.rating = rating
        self.checkbox = checkbox
        self.is_checked = is_checked

def classification(data_set):
    attributes = ['Type', 'Deadline', 'Importance', 'Level of difficulty']
    real_data = [
        ['Study/work', '1 day left', 'Very important', 'Hard', 50],
        ['Study/work', '1 day left', 'Quite important', 'Normal', 50],
        ['Study/work', '2 days left', 'Very important', 'Hard', 50],
        ['Personal', '1 day left', 'Very important', 'Normal', 50],
        ['Study/work', '3 days left', 'Very important', 'Hard', 30],
        ['Personal', '2 days left', 'Quite important', 'Hard', 30],
        ['Study/work', '3 days left', 'Not important', 'Hard', 30],
        ['Study/work', '2 days left', 'Not important', 'Normal', 30],
        ['Personal', '1 day left', 'Quite important', 'Normal', 10],
        ['Personal', '3 days left', 'Quite important', 'Normal', 10],
        ['Personal', '1 day left', 'Not important', 'Normal', 10],
        ['Personal', '3 days left', 'Not important', 'Normal', 10],
    ]
    labels = [item[-1] for item in real_data]
    features = [item[:-1] for item in real_data]
    decision_tree = DecisionTreeClassifier()
    decision_tree.fit(features, labels)
    count = sum(1 for element in data_set if element is not None)
    rated_tasks = [None] * count
    # Giving rating to each task
    for i in range(count):
        if len(sys.argv) > 1:  # debug
            print(i)
        set = [data_set[i].type_arranged, data_set[i].deadline_arranged, data_set[i].importance_arranged, data_set[i].difficulty_arranged]
        if len(sys.argv) > 1:  # debug
            print(set[0], set[1], set[2], set[3])
        rating = decision_tree.predict([set])[0]
        if len(sys.argv) > 1:  # debug
            print(rating)
        rated_tasks[i] = Classification(data_set[i].description_arranged, data_set[i].type_arranged, data_set[i].deadline_arranged, data_set[i].importance_arranged, data_set[i].difficulty_arranged, rating, None, None)
    # Add extra points to each task
    for task in rated_tasks:
        task.rating += 1 if task.type_arranged == 'Personal' else 0
        task.rating += 2 if task.type_arranged == 'Study/work' else 0
        task.rating += 1 if task.deadline_arranged == '3 days left' else 0
        task.rating += 2 if task.deadline_arranged == '2 days left' else 0
        task.rating += 3 if task.deadline_arranged == '1 day left' else 0
        task.rating += 1 if task.importance_arranged == 'Not important' else 0
        task.rating += 2 if task.importance_arranged == 'Quite important' else 0
        task.rating += 3 if task.importance_arranged == 'Very important' else 0
        task.rating += 1 if task.difficulty_arranged == 'Normal' else 0
        task.rating += 2 if task.difficulty_arranged == 'Hard' else 0
    # Bubble-sort algorithm - rearranging from highest to lowest
    for i in range(count):
        for j in range(count - 1 - i):
            if rated_tasks[j].rating < rated_tasks[j + 1].rating:
                rated_tasks[j], rated_tasks[j + 1] = rated_tasks[j + 1], rated_tasks[j]
    return rated_tasks
print(classification(['Study/work', '1 day left', 'Very important', 'Hard']))