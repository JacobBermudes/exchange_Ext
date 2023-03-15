
#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ПараметрыОбмена = ОбменМП_СлужебныйВызовСервера.ПолучитьНастройкиОбмена();
	
	ПВХДляПоиска = ПланыВидовХарактеристик.ОбменМП_НастройкиОбмена.НаименованиеМетаданных;
	СправочникНаименованиеМетаданных = ПараметрыОбмена.Получить(ПВХДляПоиска);

	Если СправочникНаименованиеМетаданных = Неопределено Или СправочникНаименованиеМетаданных = "" Тогда
		ОбщегоНазначения.СообщитьПользователю(
			"В настройках обмена с мобильным приложением необходимо установить наименование метаданных у справочника зданий для подбора объектов отбора плана обмена");
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
	Попытка
		СправочникМенеджер = Справочники[СправочникНаименованиеМетаданных];

		Для Каждого ИдентификаторОбъекта Из Объект.УникальныеИдентификаторы Цикл
			ЗданиеСтрокаТаблицы = ТаблицаЗданий.Добавить();
			ЗданиеСсылка = СправочникМенеджер.ПолучитьСсылку(ИдентификаторОбъекта.УникальныйИдентификатор);
			ЗданиеСтрокаТаблицы.Здание = ЗданиеСсылка;
		КонецЦикла;
	Исключение
		ОбщегоНазначения.СообщитьПользователю("Некорректное наименование справочника для зданий!");
		Отказ = Истина;
	КонецПопытки;
	
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	Если Параметры.Ключ.Пустая() Тогда
		ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");
		НачалоПериода = НачалоМесяца(ОбщегоНазначенияКлиент.ДатаСеанса());
		КонецПериода = КонецМесяца(ОбщегоНазначенияКлиент.ДатаСеанса());
		Месяц = ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета(ВидПериода, НачалоПериода, КонецПериода);
	Иначе
		ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");
		НачалоПериода = НачалоМесяца(Объект.МесяцНачислений);
		КонецПериода = КонецМесяца(Объект.МесяцНачислений);
		Месяц = ВыборПериодаКлиентСервер.ПолучитьПредставлениеПериодаОтчета(ВидПериода, НачалоПериода, КонецПериода);
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПередЗаписью(Отказ, ПараметрыЗаписи)
	Если Месяц <> "" Тогда
		Объект.МесяцНачислений = НачалоМесяца(НачалоПериода);
	Иначе
		ОбщегоНазначенияКлиент.СообщитьПользователю(НСтр("ru = 'Месяц начисления не выбран.'"));
		Отказ = Истина;
	КонецЕсли;
	
	Если ТаблицаЗданий.Количество() = 0 Тогда
		Отказ = Истина;
		ОбщегоНазначенияКлиент.СообщитьПользователю("Поле списка зданий не может быть пустым");
		Возврат;
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ПередЗаписьюНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	//Удаление пустых строк перед сохранением уникальных идентификаторов в табличную часть узла плана обмена
	НомерСтрокиДляУдаления = ТаблицаЗданий.Количество() - 1;
	Пока НомерСтрокиДляУдаления >= 0 цикл
		ЗданиеСсылка = ТаблицаЗданий.Получить(НомерСтрокиДляУдаления).Здание;
		Если НЕ ЗначениеЗаполнено(ЗданиеСсылка) тогда
			ТаблицаЗданий.Удалить(НомерСтрокиДляУдаления);
		КонецЕсли;
		НомерСтрокиДляУдаления = НомерСтрокиДляУдаления - 1;
	КонецЦикла;	
	//

	ТекущийОбъект.УникальныеИдентификаторы.Очистить();
			
	Для каждого ЭлементТаблицыФормы из ТаблицаЗданий цикл
		УникальныйИдентификаторЗданияСтроки = ЭлементТаблицыФормы.Здание.УникальныйИдентификатор();
		НовыйИдентификаторЗдания = ТекущийОбъект.УникальныеИдентификаторы.Добавить();
		НовыйИдентификаторЗдания.УникальныйИдентификатор = УникальныйИдентификаторЗданияСтроки;
	КонецЦикла;
	
	ПроверитьДублиЗданий(Отказ, ТекущийОбъект);
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиСобытийЭлементовШапкиФормы
&НаКлиенте
Процедура МесяцНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");  
	ОписаниеОповещения = Новый ОписаниеОповещения("МесяцОтчетаНачалоВыбораЗавершение", ЭтотОбъект);
	ВыборПериодаКлиент.ПериодНачалоВыбора(ЭтотОбъект, Элемент, СтандартнаяОбработка, 
	   ВидПериода, НачалоПериода, ОписаниеОповещения);
КонецПроцедуры

&НаКлиенте
Процедура МесяцПриИзменении(Элемент)
	ВыборПериодаКлиент.ПериодПриИзменении(Элемент, Месяц, НачалоПериода, КонецПериода);
КонецПроцедуры

&НаКлиенте
Процедура МесяцАвтоПодбор(Элемент, Текст, ДанныеВыбора, ПараметрыПолученияДанных, Ожидание, СтандартнаяОбработка)
	ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");
	ВыборПериодаКлиент.ПериодАвтоПодбор(
	     Элемент, Текст, ДанныеВыбора, Ожидание, СтандартнаяОбработка,
	     ВидПериода, Месяц, НачалоПериода, КонецПериода); 
КонецПроцедуры

&НаКлиенте
Процедура МесяцОкончаниеВводаТекста(Элемент, Текст, ДанныеВыбора, ПараметрыПолученияДанных, СтандартнаяОбработка)
	ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");
	ВыборПериодаКлиент.ПериодОкончаниеВводаТекста(
	     Элемент, Текст, ДанныеВыбора, СтандартнаяОбработка,
	     ВидПериода, Месяц, НачалоПериода, КонецПериода);
КонецПроцедуры

&НаКлиенте
Процедура МесяцОбработкаВыбора(Элемент, ВыбранноеЗначение, СтандартнаяОбработка)
	ВидПериода = ПредопределенноеЗначение("Перечисление.ДоступныеПериодыОтчета.Месяц");
	ВыборПериодаКлиент.ПериодОбработкаВыбора(
	     Элемент, ВыбранноеЗначение, СтандартнаяОбработка,
	     ВидПериода, Месяц, НачалоПериода, КонецПериода);
КонецПроцедуры
#КонецОбласти

#Область ОбработчикиСобытийЭлементовТаблицыФормыТаблицаЗданий
&НаКлиенте
Процедура ТаблицаЗданийПередНачаломДобавления(Элемент, Отказ, Копирование, Родитель, ЭтоГруппа, Параметр)
	
	Если Копирование или Отказ тогда
		Возврат;		
	КонецЕсли;
		
	ИмяФормыВыбора = СтрШаблон("Справочник.%1.Форма.ФормаВыбора", СправочникНаименованиеМетаданных);
	ОткрытьФорму(ИмяФормыВыбора,,Элемент);
	
КонецПроцедуры

&НаКлиенте
Процедура ТаблицаЗданийОбработкаВыбора(Элемент, ВыбранноеЗначение, СтандартнаяОбработка)
	НоваяСтрока = Элементы.ТаблицаЗданий.ТекущиеДанные;
	НоваяСтрока.Здание = ВыбранноеЗначение;
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции
&НаКлиенте
Процедура МесяцОтчетаНачалоВыбораЗавершение(СтруктураПериода, ДополнительныеПараметры) Экспорт
	
	Если СтруктураПериода <> Неопределено Тогда
		Месяц = СтруктураПериода.Период;
		НачалоПериода = СтруктураПериода.НачалоПериода;
		Объект.МесяцНачислений = СтруктураПериода.КонецПериода;
	КонецЕсли;
		
КонецПроцедуры

&НаСервере
Процедура ПроверитьДублиЗданий(Отказ, ТекущийОбъект)

	//@skip-check unreachable-statement
	УникальныеИдентификаторыЗданий = ТекущийОбъект.УникальныеИдентификаторы.ВыгрузитьКолонку("УникальныйИдентификатор");
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ОбменМП_МесяцыНачисленийУникальныеИдентификаторы.УникальныйИдентификатор,
		|	ОбменМП_МесяцыНачисленийУникальныеИдентификаторы.Ссылка
		|ИЗ
		|	Документ.ОбменМП_МесяцыНачислений.УникальныеИдентификаторы КАК ОбменМП_МесяцыНачисленийУникальныеИдентификаторы
		|ГДЕ
		|	ОбменМП_МесяцыНачисленийУникальныеИдентификаторы.УникальныйИдентификатор В (&УникальныеИдентификаторыЗданий)
		|	И ОбменМП_МесяцыНачисленийУникальныеИдентификаторы.Ссылка.МесяцНачислений = &МесяцНачислений
		|	И ОбменМП_МесяцыНачисленийУникальныеИдентификаторы.Ссылка <> &СсылкаНаТекущийДокумент";
	Запрос.УстановитьПараметр("УникальныеИдентификаторыЗданий", УникальныеИдентификаторыЗданий);
	Запрос.УстановитьПараметр("МесяцНачислений", Объект.МесяцНачислений);
	Запрос.УстановитьПараметр("СсылкаНаТекущийДокумент", Объект.Ссылка);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Если НЕ РезультатЗапроса.Пустой() Тогда
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
		Пока ВыборкаДетальныеЗаписи.Следующий() Цикл				
			ОбщегоНазначения.СообщитьПользователю("Здание " +
			ВыборкаДетальныеЗаписи.Здание +
			" уже добавлено в список за месяц " +
			Месяц +
			" в документе " +
			ВыборкаДетальныеЗаписи.СсылкаНаДокумент);
		КонецЦикла;
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
КонецПроцедуры
#КонецОбласти

