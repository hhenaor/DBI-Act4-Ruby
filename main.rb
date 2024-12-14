require 'pg'
require 'io/console'

def show_tables(connection)

	result = connection.exec("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
	puts "\nTablas en la base de datos:"

	result.each_with_index do |row, index|

		puts "#{index + 1}. #{row['table_name']}"

	end

	puts ""

end


def show_columns(connection, table_name)

	result = connection.exec_params("SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;", [table_name])
	puts "\nColumnas de la tabla #{table_name}:"

	result.each_with_index do |row, index|

		puts "#{index + 1}. #{row['column_name']}"

	end

	puts ""

end

def prompt(message)
	print message
	gets.chomp

end

puts "Usuario:"
user = gets.chomp

puts "Contraseña:"
password = gets.chomp

puts "Base de datos:"
database = gets.chomp

begin

	connection = PG.connect(host: 'localhost', dbname: database, user: user, password: password)
	puts "\n= Conectado! =\n"

	loop do

		puts "Acciones disponibles:"
		puts "1. CREATE: Insertar un registro en una tabla"
		puts "2. READ: Obtener registros de una tabla, basado en un criterio"
		puts "3. UPDATE: Actualizar un valor de registros de una tabla, basado en un criterio"
		puts "4. DELETE: Eliminar registros de una tabla, basado en un criterio"
		puts "5. LIST: Lista todos los registros de una tabla, permite LIMIT, ORDER BY, ASC y DESC"
		puts "6. SALIR"

		option = prompt("Elija una opcion: ")
		puts "\n==============="

		case option
		when "1"

			show_tables(connection)
		
			table = prompt("Ingrese el nombre de una tabla: ").strip
		
			show_columns(connection, table)
		
			begin

				result = connection.exec_params("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;", [table])
			
				column_names = []
				placeholders = []
				column_values = []
			
				result.each_with_index do |row, index|

					column_name = row['column_name']
					data_type = row['data_type']
			
					column_names << column_name
					placeholders << "$#{index + 1}"
			
					print "Ingrese valor para #{column_name} (tipo #{data_type}): "
					value = gets.chomp
			
					case data_type
					when 'integer'

						column_values << value.to_i

					when 'numeric', 'double precision'

						column_values << value.to_f

					else

						column_values << value

					end

				end
			
				insert_query = "INSERT INTO #{table} (#{column_names.join(', ')}) VALUES (#{placeholders.join(', ')});"
			
				connection.exec_params(insert_query, column_values)

				puts "\n===============\n"
				puts "La query se ejecuto correctamente"

			rescue PG::Error => e

				puts "Error: #{e.message}"
			
			end

		when "2"

			show_tables(connection)

			table = prompt("Ingrese el nombre de una tabla: ").strip

			begin

				result = connection.exec_params("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;",[table])

				puts "\nColumnas en la tabla:"
				columns = []

				result.each_with_index do |row, index|

					column_name = row['column_name']
					columns << column_name
					puts "#{index + 1}. #{column_name}"

				end

				column_to_search = prompt("Ingrese el nombre de una columna para buscar: ").strip

				unless columns.include?(column_to_search)

					puts "La columna no existe"
					return

				end

				value_to_search = prompt("Ingrese el valor a buscar en la columna #{column_to_search}: ").strip

				query = "SELECT * FROM \"#{table}\" WHERE \"#{column_to_search}\" = $1;"
				result_rows = connection.exec_params(query, [value_to_search])

				if result_rows.ntuples.zero?

					puts "No hay coincidencias"

				else

					puts "\nResultados encontrados en la tabla #{table}:"

					columns_in_table = result_rows.fields

					result_rows.each_with_index do |row, index|

						puts "\nRegistro #{index + 1}:"

						columns_in_table.each do |col|

							puts "#{col}: #{row[col]}"

						end

					end

					puts "\nTotal de registros: #{result_rows.ntuples}"

				end

				rescue PG::Error => e
				puts "Error: #{e.message}"

			end

		when "3"

			show_tables(connection)

			table = prompt("Ingrese el nombre de una tabla: ").strip

			begin
			result = connection.exec_params("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;",[table])

			puts "\nColumnas en la tabla:"
			columns = []

			result.each_with_index do |row, index|

				column_name = row['column_name']
				data_type = row['data_type']
				columns << column_name
				puts "#{index + 1}. #{column_name} (#{data_type})"

			end

			column_to_search = prompt("Ingrese el nombre de una columna para buscar: ").strip

			unless columns.include?(column_to_search)

				puts "La columna no existe"
				return

			end

			value_to_search = prompt("Ingrese el valor a buscar en la columna #{column_to_search}: ").strip

			query = "SELECT * FROM \"#{table}\" WHERE \"#{column_to_search}\" = $1;"
			result_rows = connection.exec_params(query, [value_to_search])

			if result_rows.ntuples.zero?

				puts "No hay coincidencias"
				return

			end

			puts "\nResultados encontrados en la tabla #{table}:"

			columns_in_table = result_rows.fields

			result_rows.each_with_index do |row, index|

				puts "\nRegistro #{index + 1}:"
				columns_in_table.each do |col|

					puts "#{col}: #{row[col]}"

				end

			end

			update_column = prompt("Ingrese el nombre de la columna que desea actualizar: ").strip

			unless columns.include?(update_column)

				puts "Columna no válida"
				return

			end

			new_value = prompt("Ingrese el nuevo valor para #{update_column}: ").strip

			update_query = "UPDATE \"#{table}\" SET \"#{update_column}\" = $1 WHERE \"#{column_to_search}\" = $2;"
			result = connection.exec_params(update_query, [new_value, value_to_search])

			puts "Registros actualizados: #{result.cmd_tuples}"

			rescue PG::Error => e

				puts "Error: #{e.message}"

			end

		when "4"

			show_tables(connection)

			table = prompt("Ingrese el nombre de una tabla: ").strip

			begin
			result = connection.exec_params("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;",[table])

			puts "\nColumnas en la tabla:"
			columns = []

			result.each_with_index do |row, index|

				column_name = row['column_name']
				data_type = row['data_type']
				columns << column_name
				puts "#{index + 1}. #{column_name} (#{data_type})"

			end

			column_to_search = prompt("Ingrese el nombre de una columna para buscar: ").strip

			unless columns.include?(column_to_search)
				puts "La columna no existe"
				return

			end

			value_to_search = prompt("Ingrese el valor a buscar en la columna #{column_to_search}: ").strip

			query = "SELECT * FROM \"#{table}\" WHERE \"#{column_to_search}\" = $1;"
			result_rows = connection.exec_params(query, [value_to_search])

			if result_rows.ntuples.zero?

				puts "No hay coincidencias"
				return

			end

			puts "\nResultados encontrados en la tabla #{table}:"

			columns_in_table = result_rows.fields

			result_rows.each_with_index do |row, index|

				puts "\nRegistro #{index + 1}:"
				columns_in_table.each do |col|
				puts "#{col}: #{row[col]}"
				end

			end

			delete_query = "DELETE FROM \"#{table}\" WHERE \"#{column_to_search}\" = $1;"
			result = connection.exec_params(delete_query, [value_to_search])

			puts "\nRegistros eliminados: #{result.cmd_tuples}"

			rescue PG::Error => e
				puts "Error: #{e.message}"
			end

		when "5"

			show_tables(connection)

			table = prompt("Ingrese el nombre de una tabla: ").strip

			begin
				result = connection.exec_params("SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1;",[table])

				columns = []
				result.each_with_index do |row, index|

					column_name = row['column_name']
					columns << column_name

				end

				limit_clause = ""
				if prompt("Limitar numero de registros? (Si/No): ").strip.downcase == "si"

					limit = prompt("Ingrese el numero de registros para mostrar: ").strip
					limit_clause = "LIMIT #{limit}"

				end

				order_clause = ""
				if prompt("Ordenar los registros? (Si/No): ").strip.downcase == "si"

					puts "\nColumnas disponibles:"
					columns.each_with_index do |col, index|
						
						puts "#{index + 1}. #{col}"

					end

					order_column = prompt("Ingrese el nombre de la columna para ordenar: ").strip
					order_direction = prompt("Por orden ascendente o descendente? (ASC/DESC): ").strip.upcase
					order_clause = "ORDER BY \"#{order_column}\" #{order_direction}"

				end

				query = "SELECT * FROM \"#{table}\" #{order_clause} #{limit_clause};"
				result_rows = connection.exec(query)

				if result_rows.ntuples.zero?

					puts "No hay registros en la tabla"

				else

					puts "\nRegistros de la tabla #{table}:"

					row_count = 0
					result_rows.each do |row|

						row_count += 1
						print "#{row_count}. "
						
						row.each do |column, value|

							print "#{column}: #{value} "

						end

						puts

					end

					puts "\nTotal de registros: #{row_count}"

				end

			rescue PG::Error => e

				puts "Error: #{e.message}"

			end

		end

	end

rescue PG::Error => e

	puts "Error: #{e.message}"

ensure

  	connection&.close

end

0