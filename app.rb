require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

before '/protected/*' do
    if session[:user_id] == nil
        redirect to ('/login')
    end
end

before '/adminprotected/*' do
    if session[:user_id] != 3
        redirect to ('/login')
    end
end

get('/protected/profile') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    owned_films = db.execute('SELECT film_id FROM user_card_join WHERE user_id = ?', session[:user_id])  
    @result = []
    owned_films.each do |film|
        film_details = db.execute('SELECT * FROM films WHERE id = ?', film["film_id"]).first
        @result.push(film_details)
    end
    slim(:profile)
end

post('/discard') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    film_id = params["card_id"]
    user_id = session[:user_id]
    result = db.execute('SELECT card_id FROM user_card_join WHERE film_id = ? and user_id = ?', [film_id, user_id])
    if result.any?
        card_id = result.first["card_id"]
        db.execute('DELETE FROM user_card_join WHERE card_id = ?', card_id)
        redirect('/protected/profile')
    end
    redirect('/protected/profile')
end

get ('/login') do
    slim(:login)
end

post('/login') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]
    @result = db.execute("SELECT * FROM users WHERE username = ?", [username])
    if @result.any?
        password_digest = @result.first['password']
        if BCrypt::Password.new(password_digest) == password
            session[:username] = username
            session[:user_id] = @result.first['id']
            redirect('/protected/profile')
        else
            return "Wrong password"
        end
    else
        return "User not found"
    end
end


get('/register') do
    slim(:register)
end

post('/register') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"] 
    password_confirmation = params["confirm_password"]
    result = db.execute("SELECT id FROM users WHERE username=?", username)
    if result.empty?
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?, ?)", [username, password_digest])
            redirect('/films')
        else
            "Passwords do not match"
        end
    else
        "Username already exists"
    end
end

get('/films') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM films")
    slim(:"films/index")
end

get('/protected/store') do
    slim(:store)
end

post('/store/open') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true

    user_id = session[:user_id]

    cards = db.execute("SELECT * FROM films ORDER BY RANDOM() LIMIT 3")
    cards.each do |card|
        db.execute("INSERT INTO user_card_join (user_id, film_id) VALUES (?, ?)", [user_id, card['id']])
    end
    @cards = cards
    slim(:pack_opened)
end

get('/adminprotected/crud') do
    # bara admin kanske?
    slim(:crud)
end

post('/crud/new') do
    name = params[:name]
    id = params[:id]
    year = params[:year]
    rarity = params[:rarity]
    poster = params[:poster]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("INSERT INTO films (name, id, year, rarity, poster) VALUES (?, ?, ?, ?, ?)", [name, id, year, rarity, poster])
    redirect("/films")
end

post('/crud/edit') do
    name = params[:name]
    id = params[:id]
    year = params[:year]
    rarity = params[:rarity]
    poster = params[:poster]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("UPDATE films SET name=?, year=?, rarity=?, poster=? WHERE id=?", [name, year, rarity, poster, id])
    redirect("/films")
end

post('/crud/delete') do
    id = params[:id]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("DELETE FROM films WHERE id=?", [id])
    redirect("/films")
end

post('/crud/delete_user') do
    username = params[:username]
    db = SQLite3::Database.new("db/database.db")
    @result = db.execute("DELETE FROM users WHERE username=?", [username])
    redirect("/films")
end

get('/protected/trade') do
    db = SQLite3::Database.new("db/database.db") 
    @result = db.execute"SELECT username FROM users"
    p @result
    slim(:trade)
end