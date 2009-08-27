/*
 * Mixi Application JavaScript Library 
 * (c)CYWORKS
 *
 * Based on Unshiu Mixi Application JavaScript Library 
 * Copyright (c) 2009 Drecom
 * http://drecom.co.jp/
 *
 * Licensed under the Unshiu Public License Version 1.1
 * http://wiki.unshiu.jp/UPL/ 
 */
;(function($) {

	var name_space = 'mixigadget';
	$.fn[name_space] = function(config){
		// 引数 デフォルト値
		config = jQuery.extend({
				session_id: "",
				session_key: "",
				base_url: "",
				view_name: gadgets.views.getCurrentView().getName()
			},config);
		
		gadgets.util.registerOnLoadHandler(gadgetInit);
		
		var klass = {
		};
		
		/**
		 *　各gadgetが読み込まれた際に一番最初に読まれる
		 */
		function gadgetInit() {
			switch(config.view_name) {
			case 'canvas':
				canvasInit();
				break;
			case 'home':
				partsInit('home');
				break;
			case 'profile':
				partsInit('profile');
				break;
			case 'preview':
				previewInit();
				break;
			default:
			}
		}
		
		/**
		 * canvasが表示された場合の処理
		 * 自分と友達の情報をアプリケーションサーバへ登録するリクエストを投げる
		 */
		function canvasInit() {
			var req = opensocial.newDataRequest();
			
			var idspec_owner = opensocial.IdSpec.PersonId.OWNER;
			var idspec_viewer = opensocial.IdSpec.PersonId.VIEWER;
			var idspec_friends = opensocial.newIdSpec({'userId':opensocial.IdSpec.PersonId.OWNER, 'groupId':opensocial.IdSpec.GroupId.FRIENDS});
			
			var friend_params = {};
			friend_params[opensocial.DataRequest.PeopleRequestFields.MAX] = 1000;
			
			req.add(req.newFetchPersonRequest(idspec_owner), "owner");
			req.add(req.newFetchPersonRequest(idspec_viewer), "viewer");
			req.add(req.newFetchPeopleRequest(idspec_friends, friend_params), "friends");
			req.send(function (res) {
				if (res.hadError()) {
					updateContainerError();
				} else {
					var params = {
						"owner" : person_to_json(res.get("owner").getData()),
						"viewer" : person_to_json(res.get("viewer").getData()),
						"friends" : people_to_json(res.get("friends").getData())
					};
					klass.requestContainer('/gadget/register', params, gadgets.io.MethodType.POST);
				}
			});
		}
		
		/**
		 * profileまたはhomeが表示された場合の処理
		 */
		function partsInit(view) {
			var req = opensocial.newDataRequest();
			req.add(req.newFetchPersonRequest(opensocial.IdSpec.PersonId.OWNER), "owner");
			req.add(req.newFetchPersonRequest(opensocial.IdSpec.PersonId.VIEWER), "viewer");
			req.send(function (res) {
				if (res.hadError()) {
					updateContainerError();
				} else {
					owner = res.get("owner").getData();
					viewer = res.get("viewer").getData();
					var params = {
						"owner" : owner.getField(opensocial.Person.Field.ID),
						"viewer" : viewer.getField(opensocial.Person.Field.ID)
					};
					klass.requestContainer('/gadget/'+view, params);
				}
			});
		}
		
		/**
		 * previewが表示された場合の処理
		 */
		function previewInit() {
			requestContainer('/gadget/preview');
		}
		
		/**
		 *　session内容を再セットアップする
		 */
		klass.setSession = function(session_key, session_id) {
			config.session_key = session_key;
			config.session_id = session_id;
		}

		/**
		 * リクエスト内容をアプリケーションサーバへなげる
		 */
		klass.requestContainer = function (urlPath, urlParams, method) {
			$('#gadget_container').startWaiting();
			requestServer(urlPath, urlParams, function(obj) {
				$('#gadget_container').stopWaiting();
				if (obj && obj.text && obj.text.length>0) {
					updateContainer(obj.text);
				} else {
					updateContainerError();
				}
			}, method);
		}
		
		/**
		 * JSによるリクエスト内容をアプリケーションサーバへなげる
		 */
		klass.requestScript = function (urlPath, urlParams, method) {
			$('#gadget_container').startWaiting();
			requestServer(urlPath, urlParams, function(obj) {
				$('#gadget_container').stopWaiting();
				if (obj && obj.text && obj.text.length>0) {
					runScript(obj.text);
				} else {
					runScriptError();
				}
			}, method);
		}
		
		/**
		 * gadgets.ioを利用してアプリケーションサーバへリクエスト処理を実際になげる
		 */
		function requestServer(urlPath, urlParams, callbackFunction, method) {
			method = method || gadgets.io.MethodType.GET;
			if (urlParams==null) {
				urlParams = {};
			} else if (typeof urlParams == "string") {
				urlParams = parseQuery(urlParams);
			}
			if (config.session_id) urlParams[config.session_key] = config.session_id;
			
			var params = {};
			params[gadgets.io.RequestParameters.METHOD] = method;
			params[gadgets.io.RequestParameters.CONTENT_TYPE] = gadgets.io.ContentType.TEXT;
			
			var url = "";
			if (method == gadgets.io.MethodType.POST) {
				url = config.base_url + urlPath;
				params[gadgets.io.RequestParameters.POST_DATA] = gadgets.io.encodeValues(urlParams);
			} else {
				url = config.base_url + urlPath;
				
				var query = toQueryString(urlParams);
				if (query.length>0) url += "?" + query;
			}
			gadgets.io.makeRequest(url, callbackFunction, params);
		}
		
		/**
		 * params内容をリクエストクエリ文字列に変換
		 */
		function toQueryString(params) {
			var query = "";
			for (var key in params) {
				query += "&" + encodeURIComponent(key) + "=" + encodeURIComponent(params[key]);
			}
			if (query.length>0) query = query.substring(1);
			return query;
		}
		
		/**
		 * リクエストクエリ文字列を解析しhashを生成する
		 */
		function parseQuery(query) {
			var params = {};
			if (query) {
				var pairs = query.split("&");
				for (var i = 0; i < pairs.length; i++) {
					var kv = pairs[i].split("=");
					params[decodeURIComponent(kv[0].replace(/\+/g, ' '))] = kv[1] ? decodeURIComponent(kv[1].replace(/\+/g, ' ')) : '';
				}
			}
			return params;
		}
		
		/**
		 * ガジェットの表示更新処理
		 */
		function updateContainer(html, evalScripts) {
			if (!html) updateContainerError();
			evalScripts = evalScripts || true;
			
			if (html.indexOf("!!NOUPDATE!!")!=0) document.getElementById('gadget_container').innerHTML = html;
			
			setTimeout(function(){ //100ms待つ
				//script実行
				if (evalScripts) {
					var ScriptFragment = '<script[^>]*>([\\S\\s]*?)<\/script>';
					var scripts = html.match(new RegExp(ScriptFragment, 'img'));
					if (scripts) {
						for (var i=0; i<scripts.length; i++) {
							var script = scripts[i].match(new RegExp(ScriptFragment, 'im'));
							if (script) runScript(script[1]);
						}
					}
				}
				gadgets.window.adjustHeight();
			}, 100);
		}
		
		/**
		 * ガジェットの表示をエラーとして更新する
		 */
		function updateContainerError() {
			updateContainer('エラーが発生しました。');
		}
		
		/**
		 * スクリプトの実行処理。
		 */
		function runScript(script) {
			try {
				eval(script);
			} catch (e) {
				runScriptError();
			}
		}
		
		/**
		 * スクリプトの実行に問題が起こった際の処理。
		 */
		function runScriptError() {
			alert('エラーが発生しました。');
		}
		
		/**
		 *　人単体情報をjsonに形式に変換
		 */
		function person_to_json(_person) {
			return gadgets.json.stringify(_person_to_hash(_person));
		}
		
		/**
		 *　人複数の情報をjsonに形式に変換
		 */
		function people_to_json(_people) {
			var people = [];
			_people.each(function(_person) {
				people.push(_person_to_hash(_person));
			});
			return gadgets.json.stringify(people);
		}
		
		/**
		 *　人情報のjsonに変換のコア
		 */
		function _person_to_hash(_person) {
			var fields = {
				'mixi_id' : opensocial.Person.Field.ID,
				'nickname' : opensocial.Person.Field.NICKNAME,
				'profile_url' : opensocial.Person.Field.PROFILE_URL,
				'thumbnail_url' : opensocial.Person.Field.THUMBNAIL_URL
			};
			var person = {};
			for (var key in fields) {
				person[key] = _person.getField(fields[key]);
			}
			person['nickname'] = _person.getDisplayName(); //bug?? adhoc
			return person;
		}
		
		$[name_space] = klass;
		$[name_space.replace(/_([a-z])/g, function () { return arguments[1].toUpperCase() })] = klass;
		
		return this;
	};

})(jQuery);