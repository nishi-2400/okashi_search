//
//  ViewController.swift
//  MyOkashi
//
//  Created by Yusuke Nishi on 2019/12/04.
//  Copyright © 2019 Swift-beginners. All rights reserved.
//

import UIKit
//iOSアプリでWebページを表示する機能
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchText.delegate = self
        
        //プレースホルダー
        searchText.placeholder = "お菓子の名前を入力してください"
        
        //Table ViewのdataSourceを設定
        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBOutlet weak var searchText: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    var okashiList: [(name:String, maker:String, link:URL, image:URL)] = []
    
    
    //検索ボタンがタップ時されたときに実行される（Search BarのDelegateメソッド:Delegateにより実行される）
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //検索に使用したキーボードを閉じる。view?
        view.endEditing(true)
        //検索で入力された値をアンラップ
        if let searchWord = searchBar.text {
            print(searchWord)
            searchOkashi(keyword: searchWord)
        }
    }
    
    //取得するJsonデータ用の構造体を宣言（商品個々のデータ）
    struct ItemJson: Codable {
        let name: String?
        let maker: String?
        let url: URL?
        let image: URL?
    }
    
    //個々のデータをリストで管理
    struct ResultJson: Codable {
        let item: [ItemJson]?
    }
    
    
    
    //検索ボタンがタップ時されたときに実行される（Search BarのDelegateメソッド:Delegateにより実行される）
    func searchOkashi(keyword: String) {
        //入力された値(keyword)をエンコード
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        //エンコードした文字列をURLにい埋め込みリクエスト用URLを生成
        guard let req_url = URL(string: "https://sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r") else {
            return
        }
        print(req_url)
        
        let req = URLRequest(url: req_url)
        
        //リクエストのデータ転送を管理するためのセッションをインスタンス化
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        //URLのデータを取得
        //セッション（リクエスト）をタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) in
            
            //セッションを終了
            session.finishTasksAndInvalidate()
            
            //例外処理
            do {
                //JSONデコーダーをインスタンス化
                let decoder = JSONDecoder()
                
                //取得したJsonデータ（data）をパースして構造体ResulttJsonのデータ構造に合わせて変数に格納
                let json = try decoder.decode(ResultJson.self, from: data!)
                
                //取得したJsonデータから、検索結果をアンラップし格納
                if let items = json.item {
                    
                    //再検索時に前回取得したデータのリストを削除
                    self.okashiList.removeAll()
                    
                    //取得したす商品情報のリストを展開
                    for item in items {
                        if let name = item.name, let maker = item.maker, let link = item.url, let image = item.image {
                            
                            //一つの商品データをタプルでまとめる
                            let okashi = (name, maker, link, image)
                            
                            //個々の商品データ（タプル）をリストに追加
                            self.okashiList.append(okashi)
                        }
                    }
                    
                    self.tableView.reloadData()
                    if let okashidbg = self.okashiList.first {
                        print("------------------------")
                        print("okashiList[0] = \(okashidbg)")
                    }
                }
            } catch {
                print("エラーが出ました")
            }
        })
        task.resume()
    }
    
    
    //使用するdataSourceメソッド
    //セルの総数を返すメソッド。必ず記述する必要あり
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return okashiList.count
    }
    
    //セルに値を設定するメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // セルを生成
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell", for: indexPath)
        
        //お菓子(セル)のタイトルをラベルに設定。
        cell.textLabel?.text = okashiList[indexPath.row].name
        
        //お菓子画像をサーバーから取得。
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image) {
            cell.imageView?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    //セルがタップされた時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //タップされたセルの選択状態を解除する
        tableView.deselectRow(at: indexPath, animated: true)
        
        //SFSafariViewControllerをインスタンス化し、
        let safariViewController = SFSafariViewController(url: okashiList[indexPath.row].link)
        
        //Safariが閉じられたときに使うDelegateメソッドが記述されている場所を指定
        safariViewController.delegate = self
        
        //Safariを開く
        present(safariViewController, animated: true, completion: nil)
    }
    
    //Safariが閉じられたときに使うDelegateメソッド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        //Safariを閉じる
        dismiss(animated: true, completion: nil)
    }
    
    
}

