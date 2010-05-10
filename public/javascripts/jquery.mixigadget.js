/*
 * Mixi Application JavaScript Library 
 * (c)CYWORKS
 * git://github.com/araimotoki/mixiapp_base.git
 *
 * Based on Unshiu Mixi Application JavaScript Library 
 * Copyright (c) 2009 Drecom
 * http://drecom.co.jp/
 *
 * Licensed under the Unshiu Public License Version 1.1
 * http://wiki.unshiu.jp/UPL/ 
 */
;(function($) {
	Deferred.define();
	var name_space = 'mixigadget';
	$.fn[name_space] = function(config){
		// 引数 デフォルト値
		config = jQuery.extend({
				session_id: "",
				session_key: "",
				viewer_id: "",
				base_url: "",
				app_url: "",
				owner_only: false,
				has_app_filter: false,
				debug_flag: false,
				register_friends_post_size: 100,
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
			var opt_params = gadgets.views.getParams();
			if (opt_params && opt_params.session_key && opt_params.session_id) {
				klass.setSession(opt_params.session_key, opt_params.session_id);
				klass.requestContainer('/gadget/top');
			} else {
				var req = opensocial.newDataRequest();
				
				var idspec_owner = opensocial.IdSpec.PersonId.OWNER;
				var idspec_viewer = opensocial.IdSpec.PersonId.VIEWER;
				var idspec_friends = opensocial.newIdSpec({'userId':opensocial.IdSpec.PersonId.OWNER, 'groupId':opensocial.IdSpec.GroupId.FRIENDS});
				
				var friend_params = {};
				friend_params[opensocial.DataRequest.PeopleRequestFields.MAX] = 1000;
				if (config.has_app_filter) friend_params[opensocial.DataRequest.PeopleRequestFields.FILTER] = opensocial.DataRequest.FilterType.HAS_APP;
				
				req.add(req.newFetchPersonRequest(idspec_owner), "owner");
				req.add(req.newFetchPersonRequest(idspec_viewer), "viewer");
				req.add(req.newFetchPeopleRequest(idspec_friends, friend_params), "friends");
				req.send(function (res) {
					if (res.hadError()) {
						updateContainerError();
					} else {
						owner_data = person_to_hash(res.get("owner").getData());
						viewer_data = person_to_hash(res.get("viewer").getData());
						friends_data = people_to_hasharray(res.get("friends").getData());
						
						if (config.owner_only && owner_data['mixi_id'] != viewer_data['mixi_id']) {
							window.open(config.app_url, '_parent');
							return false;
						}
						config.viewer_id = viewer_data['mixi_id'];
						
						var params = {
							"owner" : gadgets.json.stringify(owner_data),
							"viewer" : gadgets.json.stringify(viewer_data)
						};
						klass.requestDeferred('/gadget/register_user', params, gadgets.io.MethodType.POST)
						.next(function(data){
							runScript(data.text);
						})
						.next(function(){
							loopTimes = Math.ceil(friends_data.length / config.register_friends_post_size);
							return loop(loopTimes, function(index){
								var current_friends_data = friends_data.slice(index*config.register_friends_post_size, (index+1)*config.register_friends_post_size);
								var params = {
									"friends" : gadgets.json.stringify(current_friends_data)
								};
								return klass.requestDeferred('/gadget/register_friends', params, gadgets.io.MethodType.POST);
							});
						})
						.next(function(){
							var friend_ids = [];
							for (i in friends_data) {
								friend_ids.push(friends_data[i]['mixi_id']);
							}
							var params = {
								"friend_mixi_ids" : gadgets.json.stringify(friend_ids)
							};
							return klass.requestDeferred('/gadget/register_friendships', params, gadgets.io.MethodType.POST);
						})
						.next(function(){
							klass.requestContainer('/gadget/top');
						})
						.error(function(e){
							updateContainerError(e);
						});
					}
				});
			}
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
					config.viewer_id = viewer.getField(opensocial.Person.Field.ID);
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
			$('.loading').show();
			requestServer(urlPath, urlParams, function(data) {
				$('#gadget_container').stopWaiting();
				$('.loading').hide();
				if (data && data.rc==200) {
					updateContainer(data.text);
				} else {
					errorMessage = "ERROR : klass.requestContainer : " + urlPath + " faild."
					if (data) { errorMessage += "(" + data.rc + ")"; }
					updateContainerError(errorMessage);
				}
			}, method);
		}
		
		/**
		 * JSによるリクエスト内容をアプリケーションサーバへなげる
		 */
		klass.requestScript = function (urlPath, urlParams, method) {
			$('#gadget_container').startWaiting();
			$('.loading').show();
			requestServer(urlPath, urlParams, function(data) {
				$('#gadget_container').stopWaiting();
				$('.loading').hide();
				if (data && data.rc==200) {
					runScript(data.text);
				} else {
					errorMessage = "ERROR : klass.requestScript : " + urlPath + " faild."
					if (data) { errorMessage += "(" + data.rc + ")"; }
					runScriptError(errorMessage);
				}
			}, method);
		}
		
		/**
		 * リクエスト内容をアプリケーションサーバへなげる(jsDeferred用)
		 */
		klass.requestDeferred = function (urlPath, urlParams, method) {
			var deferred = new Deferred();
			requestServer(urlPath, urlParams, function(data) {
				if (data && data.rc==200) {
					deferred.call(data);
				} else {
					errorMessage = "ERROR : klass.requestContainer : " + urlPath + " faild."
					if (data) { errorMessage += "(" + data.rc + ")"; }
					if (config.debug_flag) {
						deferred.fail(data.text);
					} else {
						deferred.fail(errorMessage);
					}
				}
			}, method);
			return deferred;
		}
		
		/**
		 *　ユーザ招待をする画面をポップアップで表示
		 */
		klass.requestInvite = function(callbackFunction) {
			opensocial.requestShareApp("VIEWER_FRIENDS", null, function(response) {
				// 現時点で成功しても　hadError()　がかえるのでそこが解消するまで一旦サスペンド
				// if (response.hadError()) { 
				//  	updateContainerError();
				// } else {
				// }
				var params = {"invite_mixi_ids" : gadgets.json.stringify(response.getData()["recipientIds"])};
				requestServer('/gadget/register_invite', params, callbackFunction, gadgets.io.MethodType.POST);
			});
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
			urlParams["nocache"] = (new Date()).strftime('%Y%m%d%H%M%S')
			
			var params = {};
			params[gadgets.io.RequestParameters.METHOD] = method;
			params[gadgets.io.RequestParameters.CONTENT_TYPE] = gadgets.io.ContentType.TEXT;
			params[gadgets.io.RequestParameters.REFRESH_INTERVAL] = 0
			
			var url = "";
			if (method == gadgets.io.MethodType.POST) {
				url = config.base_url + urlPath;
				params[gadgets.io.RequestParameters.POST_DATA] = encodeValues(urlParams);
			} else {
				url = config.base_url + urlPath;
				
				var query = toQueryString(urlParams);
				if (query.length>0) url += (url.indexOf("?")==-1 ? "?" : "&") + query;
			}
			url += (url.indexOf("?")==-1 ? "?" : "&") + 'opensocial_viewer_id=' + config.viewer_id;
			
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
					var params_key = decodeURIComponent(kv[0].replace(/\+/g, ' '));
					var params_value = kv[1] ? decodeURIComponent(kv[1].replace(/\+/g, ' ')) : '';
					
					if(params[params_key] == null) {
						// nothing
					} else if(typeof(params[params_key]) == "string" || params[params_key] instanceof String) {
						params_value = [params[params_key], params_value];
					} else if(typeof(params[params_key]) == "array" || params[params_key] instanceof Array) {
						params_value = params[params_key].concat([params_value]);
					}
					params[params_key] = params_value;
				}
			}
			return params;
		}
		
		/**
		 *　リクエスト情報をhtmlエンコードする
		 */
		function encodeValues(fields, opt_noEscaping) {
			var escape = !opt_noEscaping;
			
			var buf = [];
			var first = false;
			for (var i in fields) if (fields.hasOwnProperty(i)) {
				if (!first) {
					first = true;
				} else {
					buf.push("&");
				}
				if (fields[i] instanceof Array) {
					var array = fields[i];
					for(var j = 0 ; j < array.length ; j++) {
						buf.push(escape ? encodeURIComponent(i) : i);
						buf.push("=");
						buf.push(escape ? encodeURIComponent(array[j]) : array[j])
						if (j != array.length - 1) {
							buf.push("&");
						}
					}
				} else {
					buf.push(escape ? encodeURIComponent(i) : i);
					buf.push("=");
					buf.push(escape ? encodeURIComponent(fields[i]) : fields[i]);
				}
			}
			return buf.join("");
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
		function updateContainerError(errorMessage) {
			message = 'mixiとの通信にエラーが発生したか、一定時間が経過したため接続を閉じました。';
			if (typeof(errorMessage) != "undefined") message += errorMessage;
			message += '<br><a href="#" onclick="location.reload();">TOPに戻る</a><br>';
			updateContainer(message);
		}
		
		/**
		 * スクリプトの実行処理。
		 */
		function runScript(script) {
			try {
				eval(script);
			} catch (e) {
				runScriptError(e);
			}
		}
		
		/**
		 * スクリプトの実行に問題が起こった際の処理。
		 */
		function runScriptError(e) {
			alert('エラーが発生しました。' + e);
		}
		
		/**
		 *　人単体情報をhashに変換
		 */
		function person_to_hash(_person) {
			var fields = {
				'mixi_id' : opensocial.Person.Field.ID,
				'nickname' : opensocial.Person.Field.NICKNAME,
//				'profile_url' : opensocial.Person.Field.PROFILE_URL,
				'thumbnail_url' : opensocial.Person.Field.THUMBNAIL_URL
			};
			var person = {};
			for (var key in fields) {
				person[key] = _person.getField(fields[key]);
			}
			person['nickname'] = _person.getDisplayName();
			return person;
		}
		
		/**
		 *　人複数の情報をhashの配列に変換
		 */
		function people_to_hasharray(_people) {
			var people = [];
			_people.each(function(_person) {
				people.push(person_to_hash(_person));
			});
			return people;
		}
		
		$[name_space] = klass;
		$[name_space.replace(/_([a-z])/g, function () { return arguments[1].toUpperCase() })] = klass;
		
		return this;
	};

})(jQuery);