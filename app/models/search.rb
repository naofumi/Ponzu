# == Thoughts about search
#
# I think that there are many ways that we can use faceted search, so we should
# use Solr.
# 
# === Ideas for faceted search
# 
# 1. For each search, we show a list of users whose names matched the query.
# 2. If the search matches presentations, we can show a list of authors that
#    were included in the presentations.
# 3. We can also show which dates match the query. Additionally, we can drill
#    down by presentations that will take place later today.
# 4. We can show which posters match the query by poster location.
# 5. Ideally, we would like to use the keywords from DBCLS to make a really fun
#    search that understands the meaning of keywords.
class Search
end