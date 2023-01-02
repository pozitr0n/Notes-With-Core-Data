//
//  ViewController.swift
//  LearnCoreData
//
//  Created by Raman Kozar on 02/01/2023.
//

import UIKit
import CoreData

class ViewController: UIViewController {
   
    @IBOutlet weak var tableView: UITableView!
    
    var notes: [NSManagedObject] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        registerTableViewCells()
        setNoteBtnToView()
        getFetchRequest()
        
    }
    
    private func registerTableViewCells() {
        
        let textFieldCell = UINib(nibName: "CustomTableViewCell", bundle: nil)
        self.tableView.register(textFieldCell, forCellReuseIdentifier: "Cell")
        
    }

    private func setNoteBtnToView() {
    
        let createNewNoteButton = UIButton()
        createNewNoteButton.setBackgroundImage(UIImage(named: "customButton"), for: .normal)
        
        view.addSubview(createNewNoteButton)
        createNewNoteButton.addTarget(self, action: #selector(handlerCreateNewNoteButtonPressed), for: .touchUpInside)
        
        createNewNoteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([createNewNoteButton.rightAnchor.constraint(equalTo: tableView.rightAnchor, constant: -40),
                                     createNewNoteButton.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -30),
                                     createNewNoteButton.heightAnchor.constraint(equalToConstant: 70),
                                     createNewNoteButton.widthAnchor.constraint(equalToConstant: 70)])
        
        
    }
    
    @objc func handlerCreateNewNoteButtonPressed() {
        
        let alert = UIAlertController(title: "Create the note", message: "", preferredStyle: .alert)
        let create = UIAlertAction(title: "Create", style: .cancel) { [unowned self] action in
            
            guard let textField = alert.textFields?.first, let noteSave = textField.text else { return }
            
            save(text: noteSave)
            tableView.reloadData()
            
        }
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        
        alert.addTextField { textField in
            textField.placeholder = "Enter note..."
        }
        
        alert.addAction(create)
        alert.addAction(cancel)
        
        present(alert, animated: true)
                
    }
    
    func save(text: String) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext)!
        let note = NSManagedObject(entity: entity, insertInto: managedContext)
        note.setValue(text, forKey: "noteName")
        
        do {
            try managedContext.save()
            notes.append(note)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
    }
    
    func update(oldText: String, newText: String) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        
        fetchRequest.predicate = NSPredicate(format: "noteName = %@", oldText)
        
        do {
            
            let results = try? managedContext.fetch(fetchRequest) as [NSManagedObject]
            
            if results?.count != 0 {
                results![0].setValue(newText, forKey: "noteName")
                try managedContext.save()
            }
            
        } catch let error as NSError {
            print("\(error)")
        }
        
        
    }
    
    func getFetchRequest() {
    
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        
        do {
            notes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Can't fetch data from database because \(error)")
        }
    
    }
    
    func editRow(_ index: IndexPath) {
        
        let alertForEdit = UIAlertController(title: "Edit the note", message: "Edit the note...", preferredStyle: .alert)
        let cancelForEdit = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let editAction = UIAlertAction(title: "Edit", style: .cancel) { [unowned self] action in
           
            guard let textField = alertForEdit.textFields?.first, let noteSave = textField.text else { return }
            
            let oldText = self.notes[index.row].value(forKeyPath: "noteName") as! String
            self.update(oldText: oldText, newText: noteSave)
           
            tableView.reloadData()
            
        }
        
        alertForEdit.addTextField { textField in
            
            textField.text = self.notes[index.row].value(forKeyPath: "noteName") as? String
            
        }
        
        alertForEdit.addAction(editAction)
        alertForEdit.addAction(cancelForEdit)
        
        present(alertForEdit, animated: true)
        
    }
    
    func delete(by indexPath: IndexPath) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(notes[indexPath.row])
        notes.remove(at: indexPath.row)
        
        do {
            try managedContext.save()
            tableView.reloadData()
        } catch let error as NSError {
            print("\(error)")
        }
        
    }
    
}

extension ViewController: UITableViewDelegate {
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editRow(indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            delete(by: indexPath)
        }
        
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = notes[indexPath.row].value(forKeyPath: "noteName") as? String
        
        // Code of the text-label color - #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
        cell.textLabel?.textColor = #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
        
        // Code of the background-color - #colorLiteral(red: 0.9600886703, green: 0.9261525273, blue: 0.8534681797, alpha: 1)
        cell.backgroundColor = #colorLiteral(red: 0.9600886703, green: 0.9261525273, blue: 0.8534681797, alpha: 1)
        
        cell.textLabel?.font = UIFont(name: "System", size: 20)
        
        return cell
        
    }
    
}

