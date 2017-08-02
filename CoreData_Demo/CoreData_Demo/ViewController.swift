//
//  ViewController.swift
//  CoreData_Demo
//
//  Created by zhangteng709 on 2017/7/23.
//  Copyright © 2017年 zhangteng709. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        insertSampleData()
        queryData()
    }
    // 保存plist文件的信息
    @objc func insertSampleData() {
        let fetch = NSFetchRequest<User>(entityName: "User")
        fetch.predicate = NSPredicate(format: "searchKey != nil")
        //获取数据上下文对象
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext

        let EntityName = "User"
        let oneUser = NSEntityDescription.insertNewObject(forEntityName: EntityName, into:context) as? User
        
        oneUser?.name = "124242"
        
        oneUser?.phone = "123213213123"
        
        
        app.saveContext()
    }
    //2、查询数据的具体操作如下
    /*
     * 利用NSFetchRequest方法来声明数据的请求，相当于查询语句
     * 利用NSEntityDescription.entityForName方法声明一个实体结构，相当于表格结构
     * 利用NSPredicate创建一个查询条件，并设置请求的查询条件
     * 通过context.fetch执行查询操作
     * 使用查询出来的数据
     */
    func queryData(){
        
        //获取数据上下文对象
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext
        
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "User"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "name = '124242'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [User]
            
            //遍历查询的结果
            for info:User in fetchedObjects{
                
                print("userEmail===\r" + info.name!)
                print("userPwd===\r" + info.phone!)
                print("+++++++++++++++++++++++++")
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

