#Область ОбработчикиСобытий

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

Процедура ПередЗаписью(Отказ)

	Если ОбменДанными.Загрузка тогда
		Возврат;
	КонецЕсли;
			
	//@skip-check event-heandler-boolean-param
	Отказ = ОшибкаВыполненияАвторизации;
КонецПроцедуры

#КонецЕсли

#КонецОбласти

#Область СлужебныеПроцедурыИФункции	

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

функция ПолучитьЗначениеCookie(Cookies, CookieName)
	
	Результат = Cookies;
	
	ПозицияCookie = Найти(Результат, CookieName);
	если не ПозицияCookie тогда
		возврат Результат;
	конецесли;
	
	Результат = Прав(Результат, СтрДлина(Результат) - (ПозицияCookie + СтрДлина(CookieName)));
	Результат = Лев(Результат, Найти(Результат, ";") - 1);
	
	возврат Результат;
	
конецфункции	

процедура ОтправитьДанные(Данные) экспорт
		
	// HTTP		
	если HTTPS тогда
		//Соединение = новый HTTPСоединение(Сервер, Порт,,,,, новый ЗащищенноеСоединениеOpenSSL()); // -- 18082021 ГрачевИА
		Соединение = новый HTTPСоединение(Сервер, Порт,,,, 300, новый ЗащищенноеСоединениеOpenSSL()); // ++ 18082021 ГрачевИА
		Схема = "https"
	иначе
		Соединение = новый HTTPСоединение(Сервер, Порт);
		Схема = "http"
	конецесли;
	
	// Получение CSRF-токена
	Запрос = новый HTTPЗапрос("/api/v1/core/auth/init/");
	
	попытка
		Ответ = Соединение.Получить(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат;
	конецпопытки;
	
	// ++ 11082021 ГрачевИА
	// Запись ответа в случае ошибки при получении CSRF-токена. ГрачевИА
	ТелоСтрокой = Ответ.ПолучитьТелоКакСтроку();
	Результат = ЗначениеИзСтрокиJSON(ТелоСтрокой);
	Если Ответ.КодСостояния <> 200 Тогда
		ВидОперации = НСтр("ru = 'Обмен с мобильным приложением.'");
		ТекстОшибки = НСтр("ru = 'Ошибка при получении CSRF-токена на сервере МП.'");
		ПодробныйТекстОшибки = ТекстОшибки + Символы.ПС
		+ ТелоСтрокой + Символы.ПС
		+ "POST" + " "
		+ БизнесСеть.АдресСоединенияURL(Сервер, Порт,
		Запрос.АдресРесурса, Соединение.ЗащищенноеСоединение <> Неопределено)
		+ Символы.ПС
		+ СтрШаблон(НСтр("ru = 'Ответ: %1'"), Ответ.КодСостояния);
		Если ТипЗнч(Результат) = Тип("Структура") И Результат.Свойство("errors") Тогда
			// Попытка получить значение Результат.errors, если такое существует при возникновении ошибки. ГрачевИА
			errors = "";
			//@skip-check empty-except-statement
			Попытка
				errors = Результат.errors;
			Исключение
			КонецПопытки;
			ПодробныйТекстОшибки = ПодробныйТекстОшибки + Символы.ПС + errors;
		КонецЕсли;
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		ЭлектронноеВзаимодействие.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
	КонецЕсли;
	// ++ ГрачевИА
	
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	
	//// Авторизация
	//// ++ 18082021 Увеличено время на две минуты между авторизациями. ГрачевИА
	//ПериодЗадержки = 120;
	//БудущееВремя = ТекущаяДата() + ПериодЗадержки;
	//Пока ТекущаяДата() < БудущееВремя Цикл
	//КонецЦикла;
	//// ++ ГрачевИА
	
	//Ерохин
	ПериодЗадержки = 3;
	ОбщегоНазначенияБТС.Пауза(ПериодЗадержки);
	// 
	
	Запрос.АдресРесурса = "/api/v1/core/auth/sign_in/";
	Запрос.Заголовки.Вставить("Referer", Схема + "://" + Сервер + ":" + Формат(Порт, "ЧГ=0") + "/");
	Запрос.Заголовки.Вставить("Content-Type", "application/x-www-form-urlencoded");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + ";");
	
	ТелоЗапроса = "username=" + ИмяПользователя;
	ТелоЗапроса = ТелоЗапроса + "&password=" + Пароль;
	ТелоЗапроса = ТелоЗапроса + "&csrfmiddlewaretoken=" + CSRFТокен;
	
	Запрос.УстановитьТелоИзСтроки(ТелоЗапроса);
	
	попытка
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат;
	конецпопытки;
	
	// ++ 11082021 ГрачевИА
	// Запись ответа в случае ошибки при авторизации. ГрачевИА
	ОшибкаВыполненияАвторизации = Ложь;
	ТелоСтрокой = Ответ.ПолучитьТелоКакСтроку();
	Результат = ЗначениеИзСтрокиJSON(ТелоСтрокой);
	Если Ответ.КодСостояния <> 200 Тогда	
		ВидОперации = НСтр("ru = 'Обмен с мобильным приложением.'");
		ТекстОшибки = НСтр("ru = 'Ошибка авторизации на сервере МП.'");
		ПодробныйТекстОшибки = ТекстОшибки + Символы.ПС
		+ ТелоСтрокой + Символы.ПС
		+ "POST" + " "
		+ БизнесСеть.АдресСоединенияURL(Сервер, Порт,
		Запрос.АдресРесурса, Соединение.ЗащищенноеСоединение <> Неопределено)
		+ Символы.ПС
		+ СтрШаблон(НСтр("ru = 'Ответ: %1'"), Ответ.КодСостояния);
		Если ТипЗнч(Результат) = Тип("Структура") И Результат.Свойство("errors") Тогда
			// Попытка получить значение Результат.errors, если такое существует при возникновении ошибки. ГрачевИА
			errors = "";
			//@skip-check empty-except-statement
			Попытка
				errors = Результат.errors;
			Исключение
			КонецПопытки;
			ПодробныйТекстОшибки = ПодробныйТекстОшибки + Символы.ПС + errors;
		КонецЕсли;
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		ЭлектронноеВзаимодействие.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		
		// Отмена выполнения текущего фонового задания и создание нового регламентного задания через промежуток - один час. ГрачевИА
		//Если Ответ.КодСостояния = 500 Тогда
		//	ОшибкаВыполненияАвторизации = Истина;
		//	ОбменСМобильнымПриложениемПереопределяемый.ОтменаВыполненияФоновогоЗадания();
		//КонецЕсли;

	КонецЕсли;
	// ++ ГрачевИА
	
	// Обновление csrf токена и идентификатора сессии
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	SessionID = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "sid");
	
	Boundary = Строка(новый УникальныйИдентификатор());
			
	ТелоЗапроса = новый ТекстовыйДокумент();
	
	ТелоЗапроса.ДобавитьСтроку("--" + Boundary);
	ТелоЗапроса.ДобавитьСтроку("Content-Disposition: form-data; name=""exchange""; filename=""exchange.xml""");
	ТелоЗапроса.ДобавитьСтроку("Content-Type: text/xml");
	ТелоЗапроса.ДобавитьСтроку("");
	ТелоЗапроса.ДобавитьСтроку(Данные);
	
	ТелоЗапроса.ДобавитьСтроку("--" + Boundary);
	ТелоЗапроса.ДобавитьСтроку("Content-Disposition: form-data; name=""csrfmiddlewaretoken""");
	ТелоЗапроса.ДобавитьСтроку("");
	ТелоЗапроса.ДобавитьСтроку(CSRFТокен);
	
	ТелоЗапроса.ДобавитьСтроку("--" + Boundary + "--");
	
	ИмяФайлаТелаЗапроса = ПолучитьИмяВременногоФайла();
	ТелоЗапроса.Записать(ИмяФайлаТелаЗапроса);
	
	////	
	//ИмяФайлаТелаЗапроса = ПолучитьИмяВременногоФайла();
	//FSO = Новый COMОбъект("Scripting.FileSystemObject");
	//Stream = FSO.CreateTextFile(ИмяФайлаТелаЗапроса, -1, 0);
	//
	//Stream.Write("--" + Boundary);
	//Stream.WriteLine("Content-Disposition: form-data; name=""exchange""; filename=""exchange.xml""");
	//Stream.WriteLine("Content-Type: text/xml");
	//Stream.WriteLine("");
	//Stream.WriteLine(Данные);
	//
	//Stream.WriteLine("--" + Boundary);
	//Stream.WriteLine("Content-Disposition: form-data; name=""csrfmiddlewaretoken""");
	//Stream.WriteLine("");
	//Stream.WriteLine(CSRFТокен);
	//
	//Stream.WriteLine("--" + Boundary + "--");
	//
	//Stream.Close();
	////
	
	Запрос.АдресРесурса = "/api/v1/exchange/";
	Запрос.Заголовки.Вставить("Referer", Схема + "://" + Сервер + ":" + Формат(Порт, "ЧГ=0") + "/");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + "; sid=" + SessionID + ";");
	Запрос.Заголовки.Вставить("Content-Type", "multipart/form-data; boundary=" + Boundary);
	Запрос.УстановитьИмяФайлаТела(ИмяФайлаТелаЗапроса);
	
	попытка
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
	конецпопытки;
	// ++ 11082021 ГрачевИА
	// Запись ответа в случае ошибки отправки пакета. ГрачевИА
	ТелоСтрокой = Ответ.ПолучитьТелоКакСтроку();
	Результат = ЗначениеИзСтрокиJSON(ТелоСтрокой);
	Если Ответ.КодСостояния <> 200 И НЕ ОшибкаВыполненияАвторизации Тогда
		ВидОперации = НСтр("ru = 'Обмен с мобильным приложением.'");
		ТекстОшибки = НСтр("ru = 'Ошибка отправки post-запроса на сервер МП.'");
		ПодробныйТекстОшибки = ТекстОшибки + Символы.ПС
		+ ТелоСтрокой + Символы.ПС
		+ "POST" + " "
		+ БизнесСеть.АдресСоединенияURL(Сервер, Порт,
		Запрос.АдресРесурса, Соединение.ЗащищенноеСоединение <> Неопределено)
		+ Символы.ПС
		+ СтрШаблон(НСтр("ru = 'Ответ: %1'"), Ответ.КодСостояния);
		Если ТипЗнч(Результат) = Тип("Структура") И Результат.Свойство("errors") Тогда
			// Попытка получить значение Результат.errors, если такое существует при возникновении ошибки. ГрачевИА
			errors = "";
			//@skip-check empty-except-statement
			Попытка
				errors = Результат.errors;
			Исключение
			КонецПопытки;
			ПодробныйТекстОшибки = ПодробныйТекстОшибки + Символы.ПС + errors;
		КонецЕсли;
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		ЭлектронноеВзаимодействие.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
	КонецЕсли;
	// ГрачевИА
	
	Запрос = неопределено;
	Соединение = неопределено;
	
	УдалитьФайлы(ИмяФайлаТелаЗапроса);
	
конецпроцедуры

функция ПолучитьЗаголовки() экспорт
		
	// HTTP		
	если HTTPS тогда
		//Соединение = новый HTTPСоединение(Сервер, Порт,,,,, новый ЗащищенноеСоединениеOpenSSL()); // -- 18082021 ГрачевИА
		Соединение = новый HTTPСоединение(Сервер, Порт,,,, 300, новый ЗащищенноеСоединениеOpenSSL()); // ++ 18082021 ГрачевИА
		Схема = "https"
	иначе
		Соединение = новый HTTPСоединение(Сервер, Порт);
		Схема = "http"
	конецесли;
	
	// Получение CSRF-токена
	Запрос = новый HTTPЗапрос("/api/v1/core/auth/init/");
	
	попытка
		Ответ = Соединение.Получить(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат неопределено;
	конецпопытки;
	
	// ++ 11082021 ГрачевИА
	// Запись ответа в случае ошибки при получении CSRF-токена. ГрачевИА
	ТелоСтрокой = Ответ.ПолучитьТелоКакСтроку();
	Результат = ЗначениеИзСтрокиJSON(ТелоСтрокой);
	Если Ответ.КодСостояния <> 200 Тогда
		ВидОперации = НСтр("ru = 'Обмен с мобильным приложением.'");
		ТекстОшибки = НСтр("ru = 'Ошибка при получении CSRF-токена на сервере МП.'");
		ПодробныйТекстОшибки = ТекстОшибки + Символы.ПС
		+ ТелоСтрокой + Символы.ПС
		+ "POST" + " "
		+ БизнесСеть.АдресСоединенияURL(Сервер, Порт,
		Запрос.АдресРесурса, Соединение.ЗащищенноеСоединение <> Неопределено)
		+ Символы.ПС
		+ СтрШаблон(НСтр("ru = 'Ответ: %1'"), Ответ.КодСостояния);
		Если ТипЗнч(Результат) = Тип("Структура") И Результат.Свойство("errors") Тогда
			// Попытка получить значение Результат.errors, если такое существует при возникновении ошибки. ГрачевИА
			errors = "";
			//@skip-check empty-except-statement
			Попытка
				errors = Результат.errors;
			Исключение
			КонецПопытки;
			ПодробныйТекстОшибки = ПодробныйТекстОшибки + Символы.ПС + errors;
		КонецЕсли;
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		ЭлектронноеВзаимодействие.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
	КонецЕсли;
	// ++ ГрачевИА
	
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	
	//// Авторизация
	//// ++ 18082021 Увеличено время на две минуты между авторизациями. ГрачевИА
	//ПериодЗадержки = 120;
	//БудущееВремя = ТекущаяДата() + ПериодЗадержки;
	//Пока ТекущаяДата() < БудущееВремя Цикл
	//КонецЦикла;
	//// ++ ГрачевИА
	
	//Ерохин
	ПериодЗадержки = 3; //2 минуты
	ОбщегоНазначенияБТС.Пауза(ПериодЗадержки);
	// 
	
	Запрос.АдресРесурса = "/api/v1/core/auth/sign_in/";
	Запрос.Заголовки.Вставить("Referer", Схема + "://" + Сервер + ":" + Формат(Порт, "ЧГ=0") + "/");
	Запрос.Заголовки.Вставить("Content-Type", "application/x-www-form-urlencoded");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + ";");
	
	ТелоЗапроса = "username=" + ИмяПользователя;
	ТелоЗапроса = ТелоЗапроса + "&password=" + Пароль;
	ТелоЗапроса = ТелоЗапроса + "&csrfmiddlewaretoken=" + CSRFТокен;
	
	Запрос.УстановитьТелоИзСтроки(ТелоЗапроса);
	
	попытка
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат неопределено;
	конецпопытки;
	
	// ++ 11082021 ГрачевИА
	// Запись ответа в случае ошибки при авторизации. ГрачевИА
	ОшибкаВыполненияАвторизации = Ложь;
	ТелоСтрокой = Ответ.ПолучитьТелоКакСтроку();
	Результат = ЗначениеИзСтрокиJSON(ТелоСтрокой);
	Если Ответ.КодСостояния <> 200 Тогда	
		ВидОперации = НСтр("ru = 'Обмен с мобильным приложением.'");
		ТекстОшибки = НСтр("ru = 'Ошибка авторизации на сервере МП.'");
		ПодробныйТекстОшибки = ТекстОшибки + Символы.ПС
		+ ТелоСтрокой + Символы.ПС
		+ "POST" + " "
		+ БизнесСеть.АдресСоединенияURL(Сервер, Порт,
		Запрос.АдресРесурса, Соединение.ЗащищенноеСоединение <> Неопределено)
		+ Символы.ПС
		+ СтрШаблон(НСтр("ru = 'Ответ: %1'"), Ответ.КодСостояния);
		Если ТипЗнч(Результат) = Тип("Структура") И Результат.Свойство("errors") Тогда
			// Попытка получить значение Результат.errors, если такое существует при возникновении ошибки. ГрачевИА
			errors = "";
			//@skip-check empty-except-statement
			Попытка
				errors = Результат.errors;
			Исключение
			КонецПопытки;
			ПодробныйТекстОшибки = ПодробныйТекстОшибки + Символы.ПС + errors;
		КонецЕсли;
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		ЭлектронноеВзаимодействие.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		
		// Отмена выполнения текущего фонового задания и создание нового регламентного задания через промежуток - один час. ГрачевИА
		//Если Ответ.КодСостояния = 500 Тогда
		//	ОшибкаВыполненияАвторизации = Истина;
		//	ОбменСМобильнымПриложениемПереопределяемый.ОтменаВыполненияФоновогоЗадания();
		//КонецЕсли;

	КонецЕсли;
	// ++ ГрачевИА
	
	// Обновление csrf токена и идентификатора сессии 
	 		
	возврат Ответ;
конецфункции

процедура ОтправитьКвитанцию(Ответ, ДанныеJSON) экспорт
	
	// HTTP		
	если HTTPS тогда
		//Соединение = новый HTTPСоединение(Сервер, Порт,,,,, новый ЗащищенноеСоединениеOpenSSL()); // -- 18082021 ГрачевИА
		Соединение = новый HTTPСоединение(Сервер, Порт,,,, 300, новый ЗащищенноеСоединениеOpenSSL()); // ++ 18082021 ГрачевИА
		Схема = "https"
	иначе
		Соединение = новый HTTPСоединение(Сервер, Порт);
		Схема = "http"
	конецесли;
	
	
	// Обновление csrf токена и идентификатора сессии
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	SessionID = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "sid");
	
		// Получение CSRF-токена
	Запрос = новый HTTPЗапрос("/api/v1/exchange/invoices/");
	Запрос.Заголовки.Вставить("Referer", Схема + "://" + Сервер + ":" + Формат(Порт, "ЧГ=0") + "/");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + "; sid=" + SessionID + ";");
	Запрос.Заголовки.Вставить("Content-Type", "application/json");
	Запрос.УстановитьТелоИзСтроки(ДанныеJSON,"windows-1251",ИспользованиеByteOrderMark.НеИспользовать);
	
	попытка
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
		//Сообщить(Ответ);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		//Сообщить(Описание);
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
	конецпопытки;
конецпроцедуры

функция ПолучитьДанные() экспорт
	
	// HTTP		
	если HTTPS тогда
		Соединение = новый HTTPСоединение(Сервер, Порт,,,,, новый ЗащищенноеСоединениеOpenSSL());
		Схема = "https"
	иначе
		Соединение = новый HTTPСоединение(Сервер, Порт);
		Схема = "http"
	конецесли;
	
	// Получение CSRF-токена
	Запрос = новый HTTPЗапрос("/api/v1/core/auth/init/");
	
	попытка
		Ответ = Соединение.Получить(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат неопределено;
	конецпопытки;
	
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	
	// Авторизация
	Запрос.АдресРесурса = "/api/v1/core/auth/sign_in/";
	Запрос.Заголовки.Вставить("Referer", Схема + "://" + Сервер + ":" + Формат(Порт, "ЧГ=0") + "/");
	Запрос.Заголовки.Вставить("Content-Type", "application/x-www-form-urlencoded");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + ";");
	
	ТелоЗапроса = "username=" + ИмяПользователя;
	ТелоЗапроса = ТелоЗапроса + "&password=" + Пароль;
	ТелоЗапроса = ТелоЗапроса + "&csrfmiddlewaretoken=" + CSRFТокен;
	
	Запрос.УстановитьТелоИзСтроки(ТелоЗапроса);
	
	попытка
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
		
		возврат неопределено;
	конецпопытки;
	
	// Обновление csrf токена и идентификатора сессии
	CSRFТокен = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "csrftoken");
	SessionID = ПолучитьЗначениеCookie(Ответ.Заголовки.Получить("Set-Cookie"), "sid");
	
	Запрос.Заголовки.Удалить("Content-Type");
	Запрос.Заголовки.Вставить("Cookie", "csrftoken=" + CSRFТокен + "; sid=" + SessionID + ";");
	
	Запрос.АдресРесурса = "/api/v1/exchange/";

	попытка
		Ответ = Соединение.Получить(Запрос);
	исключение
		Описание = "При выполнении обмена с сервером: " + Сервер + ":" + Порт;
		Описание = Описание + " произошла ошибка" + Символы.ВК + Символы.ПС;
		Описание = Описание + ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Обмен данными с мобильным приложением", УровеньЖурналаРегистрации.Ошибка,,, Описание);
	конецпопытки;
	
	Запрос = неопределено;
	Соединение = неопределено;
	
	возврат Ответ.ПолучитьТелоКакСтроку();
	
конецфункции

// Получение данных из строки в формате JSON. // ++ 11082021 ГрачевИА
//
Функция ЗначениеИзСтрокиJSON(Значение)
	
	Если ТипЗнч(Значение) <> Тип("Строка")
		Или ПустаяСтрока(Значение)
		Или Лев(Значение, 1) = "<" Тогда
		Возврат Значение;
	КонецЕсли;
	
	Результат = Неопределено;
	ЧтениеJSON = Новый ЧтениеJSON;
	Попытка
		ЧтениеJSON.УстановитьСтроку(Значение);
		Результат = ПрочитатьJSON(ЧтениеJSON);
		ЧтениеJSON.Закрыть();
	Исключение
		//Биль, Технолинк, 28.10.2021
		//изменилось расположение процедуры ОбработатьОшибку после обновления
		//ЭлектронноеВзаимодействиеСлужебныйВызовСервера.ОбработатьОшибку(ВидОперации, ПодробныйТекстОшибки, ТекстОшибки, "РегламентныеЗадания");
		//ЭлектронноеВзаимодействие.ВыполнитьЗаписьСобытияПоЭДВЖурналРегистрации(
		//	ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()), "РегламентныеЗадания");
		
		ЗаписьЖурналаРегистрации("Ошибка JSON", УровеньЖурналаРегистрации.Ошибка,,, ОписаниеОшибки());
	КонецПопытки;
	
	Возврат Результат;
	
КонецФункции
// ++ 11082021


#КонецЕсли

#КонецОбласти