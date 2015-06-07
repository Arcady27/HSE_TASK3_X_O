 var prefix = "/api/server/";
var N = 100;
var M = 100;
var symbols =["X", "O", "*", "&", "%", "V", "#", "@", ">", "<"];
$(document).ready(function() {
    var players = [];
    var symbols = [];
    create_field();
    $("#button").attr('status','join');
    setInterval(update_players,500);
    setInterval(update_field,500);

    function create_field() {
        var field = $('#field');
        field.html();
        var offset_l = field.offset();
        offset_l.top = 0;
        offset_l.left= 0;
        doc_w = $(document).width();
        doc_h = $(document).height();
        for (var x = 0; x <= N; x++)
        {
            for (var y = 0; y <= M; y++)
            {
                var st = "<div class='cell' X='x1' Y='y1' style='top:p_tpx; left:p_lpx; line-height: 28px; align-content: center; alignment:center; text-align: center; vertical-align: middle' >";
                st = st.replace("x1",x);
                st = st.replace("y1",y);
                st = st.replace("p_t",offset_l.top+32*y);
                st = st.replace("p_l",offset_l.left+32*x);
                field.append(st);
            }
        }
        /*var cell = $(".cell");
        cell.click(function(){
            var Name = $("#name");
            var X = cell.attr("X");
            var Y = cell.attr("Y");
            make_turn(Name,X,Y);

        })        */
    }

    function join(num) {
        var Name = $("#name").val();
        var inp = $("#name");
        console.log(Name);
        if (Name.length > 0) {
            $.ajax({
            url: prefix + "join/" + Name,
            dataType: "text"
            }).done(function (str) {
            if ("ok" == str) {
                $("#button").attr("status","leave");
                inp.attr('disabled',true);
                $("#button").removeClass("btn-primary").addClass("btn-danger").text("Выйти из игры");
            }
            else if (str == "not_ok")
                alert("Введите другое имя. Игрок с таким именем уже существует(");
            });

        }
        else
            alert("Введите имя");

    }

    function leave() {
        var inp = $("#name");
        var Name = $("#name").val();
        if (Name.length > 0) {
            $.ajax({
                url: prefix + "leave/" + Name,
                dataType:"text"
            }).done(function(str){
                if (str == "ok"){
                    $("#button").attr("status","join");
                    inp.val("");
                    inp.attr("disabled", false);
                    $("#button").removeClass("btn-danger").addClass("btn-primary").text("Присоединиться к игре");


                }
            });
        }

    }

    $("#button").click(function(){
        var inp = $("#name");
        var status = $(this).attr("status");
        console.log(status)
        if (status == "join")
        {
            join(0);
        }
        else
        {
            leave();
        }
    });

    function update_players() {
        var list_html = $("#list");
        //list_html.html("<li>sad<li>");
        $.ajax({
            url: prefix + "getPlayers",
            dataType: "json"
        }).done(function(data) {
            players_list = data.players;

            //console.log(players_list)                    ;
            var tag_html = "";

            /*for (var i = 0; i < players_list.length; i++)
            {

                var one_player = players_list[i];

                var symbol_c = CurrentSymbol(i);

                tag_html = tag_html +   "<li>"  + one_player + ": " + symbol_c+  "</li>";
            }
            list_html.html(tag_html); */
        });

        $.ajax({
            url: prefix + "getSymbols",
            dataType: "json"
        }).done(function(data) {
            var symbols_list = data.symbols;
            symbols = symbols_list;
            //console.log(symbols_list)                    ;
            var tag_html = "";

            if (players_list!=players)
            {
                players = players_list;
                for (var i = 0; i < symbols_list.length; i++)
                {
                    var symbol_c = symbols_list[i];
                    var one_player = players[i];
                    tag_html = tag_html + "<li>" + one_player + ": " + symbol_c + "</li>";
                }
                list_html.html(tag_html);
            }
        });
    }

    function playerSymbol(Name)
    {
        //console.log(symbols);
        //console.log(Name);
        //console.log(players);

        for (var i = 0; i < players.length; i++)
        {
            if (players[i] == Name.toString())
            {
                return symbols[i];
            }
        }
        return "";
    }

    function CurrentSymbol(ind){
        if (ind < symbols.length){
            return symbols[ind];
        }
        else {
            return "" + 1;
        }
    }

    function update_field() {
        //console.log("updating_field");
        $.ajax({
            url: prefix + "getField",
            dataType: "json"
        }).done(function(data) {
            var field = data;
            for (var i = 0; i < field.length; i++)
            {
                var cell = field[i];
                var symbol = playerSymbol(cell.player);

                // $(".cell[X='" + cell.x + "'][Y='" + cell.y + "']").text(symbol);
                $(".cell[X='" + cell.x + "'][Y='" + cell.y + "']").css('color', 'blue');
                $(".cell[X='" + cell.x + "'][Y='" + cell.y + "']").css('font-size', '28px');
                $(".cell[X='" + cell.x + "'][Y='" + cell.y + "']").text(symbol);
            }
        });
    }
    function update_winner() {
        console.log("updating_winner");
        $.ajax({
            url: prefix + "getWinner",
            dataType: "text"
        }).done(function(data) {
            data = data.substring(2, data.length - 2);
            //console.log(data);
            var Name = $("#name").val().toString();

            if (data == Name)
            {
                alert("Поздравляем! Вы победили.")
            }
            else if (data.name != "nobody") {
                alert("Вы проиграли((( Победил: " + data);
            }

        });
    }

    $(".cell").click(function(){
        var Name = $("#name").val();
        var X = $(this).attr("X");
        var Y = $(this).attr("Y");
        console.log(Name);
        make_turn(Name,X,Y);
    });

    function make_turn(Name,X,Y)
    {
        $.ajax({
            url: prefix + "makeTurn" +"/" + Name + "/" + X + "/" + Y,
            dataType: "text"
        }).done(function(data){
           if (data == "end_game")
           {
               update_field();
               update_winner();
                //alert("Конец игры!");
           }
           else if (data == "no_winner"){
                update_field();
           }
           else if (data == "not_your_turn")
           {
                alert("Сейчас не ваш ход!");
           }
           else if (data == "busy")
           {
                alert("Данная клетка занята, выберите другую клетку");
           }
        });
    }

    function reset(){
        $.ajax({
            erl: prefix + "reset",
            dataType: "text"
        }).done(function(data){
            if (data == "ok")
            {

            }
        });
    }
})
