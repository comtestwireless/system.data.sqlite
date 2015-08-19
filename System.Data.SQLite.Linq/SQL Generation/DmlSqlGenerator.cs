//---------------------------------------------------------------------
// <copyright file="DmlSqlGenerator.cs" company="Microsoft">
//      Portions of this file copyright (c) Microsoft Corporation
//      and are released under the Microsoft Pulic License.  See
//      http://archive.msdn.microsoft.com/EFSampleProvider/Project/License.aspx
//      or License.txt for details.
//      All rights reserved.
// </copyright>
//---------------------------------------------------------------------

#if USE_ENTITY_FRAMEWORK_6
namespace System.Data.SQLite.EF6
#else
namespace System.Data.SQLite.Linq
#endif
{
  using System;
  using System.Collections.Generic;
  using System.Diagnostics;
  using System.Globalization;
  using System.Text;
  using System.Data;
  using System.Data.Common;

#if USE_ENTITY_FRAMEWORK_6
  using System.Data.Entity.Core.Metadata.Edm;
  using System.Data.Entity.Core.Common.CommandTrees;
#else
  using System.Data.Metadata.Edm;
  using System.Data.Common.CommandTrees;
#endif

    /// <summary>
  /// Class generating SQL for a DML command tree.
  /// </summary>
  internal static class DmlSqlGenerator
  {
    private static readonly int s_commandTextBuilderInitialCapacity = 256;

    internal static string GenerateUpdateSql(DbUpdateCommandTree tree, out List<DbParameter> parameters)
    {
      StringBuilder commandText = new StringBuilder(s_commandTextBuilderInitialCapacity);
      ExpressionTranslator translator = new ExpressionTranslator(commandText, tree, null != tree.Returning, "UpdateFunction");

      // update [schemaName].[tableName]
      commandText.Append("UPDATE ");
      tree.Target.Expression.Accept(translator);
      commandText.AppendLine();

      // set c1 = ..., c2 = ..., ...
      bool first = true;
      commandText.Append("SET ");
      foreach (DbSetClause setClause in tree.SetClauses)
      {
        if (first) { first = false; }
        else { commandText.Append(", "); }
        setClause.Property.Accept(translator);
        commandText.Append(" = ");
        setClause.Value.Accept(translator);
      }

      if (first)
      {
        // If first is still true, it indicates there were no set
        // clauses. Introduce a fake set clause so that:
        // - we acquire the appropriate locks
        // - server-gen columns (e.g. timestamp) get recomputed
        //
        // We use the following pattern:
        //
        //  update Foo
        //  set @i = 0
        //  where ...
        DbParameter parameter = translator.CreateParameter(default(Int32), DbType.Int32);
        commandText.Append(parameter.ParameterName);
        commandText.Append(" = 0");
      }
      commandText.AppendLine();

      // where c1 = ..., c2 = ...
      commandText.Append("WHERE ");
      tree.Predicate.Accept(translator);
      commandText.AppendLine(";");

      // generate returning sql
      GenerateReturningSql(commandText, tree, translator, tree.Returning, false);

      parameters = translator.Parameters;
      return commandText.ToString();
    }

    internal static string GenerateDeleteSql(DbDeleteCommandTree tree, out List<DbParameter> parameters)
    {
      StringBuilder commandText = new StringBuilder(s_commandTextBuilderInitialCapacity);
      ExpressionTranslator translator = new ExpressionTranslator(commandText, tree, false, "DeleteFunction");

      // delete [schemaName].[tableName]
      commandText.Append("DELETE FROM ");
      tree.Target.Expression.Accept(translator);
      commandText.AppendLine();

      // where c1 = ... AND c2 = ...
      commandText.Append("WHERE ");
      tree.Predicate.Accept(translator);

      parameters = translator.Parameters;

      commandText.AppendLine(";");
      return commandText.ToString();
    }

    internal static string GenerateInsertSql(DbInsertCommandTree tree, out List<DbParameter> parameters)
    {
      StringBuilder commandText = new StringBuilder(s_commandTextBuilderInitialCapacity);
      ExpressionTranslator translator = new ExpressionTranslator(commandText, tree, null != tree.Returning, "InsertFunction");

      // insert [schemaName].[tableName]
      commandText.Append("INSERT INTO ");
      tree.Target.Expression.Accept(translator);

      if (tree.SetClauses.Count > 0)
      {
        // (c1, c2, c3, ...)
        commandText.Append("(");
        bool first = true;
        foreach (DbSetClause setClause in tree.SetClauses)
        {
          if (first) { first = false; }
          else { commandText.Append(", "); }
          setClause.Property.Accept(translator);
        }
        commandText.AppendLine(")");

        // values c1, c2, ...
        first = true;
        commandText.Append(" VALUES (");
        foreach (DbSetClause setClause in tree.SetClauses)
        {
          if (first) { first = false; }
          else { commandText.Append(", "); }
          setClause.Value.Accept(translator);

          translator.RegisterMemberValue(setClause.Property, setClause.Value);
        }
        commandText.AppendLine(");");
      }
      else // No columns specified.  Insert an empty row containing default values by inserting null into the rowid
      {
        commandText.AppendLine(" DEFAULT VALUES;");
      }

      // generate returning sql
      GenerateReturningSql(commandText, tree, translator, tree.Returning, true);

      parameters = translator.Parameters;
      return commandText.ToString();
    }

    // Generates T-SQL describing a member
    // Requires: member must belong to an entity type (a safe requirement for DML
    // SQL gen, where we only access table columns)
    private static string GenerateMemberTSql(EdmMember member)
    {
      return SqlGenerator.QuoteIdentifier(member.Name);
    }

    /// <summary>
    /// This method attempts to determine if the specified table has an integer
    /// primary key (i.e. "rowid").  If so, it sets the
    /// <paramref name="primaryKeyMember" /> parameter to the right
    /// <see cref="EdmMember" />; otherwise, the
    /// <paramref name="primaryKeyMember" /> parameter is set to null.
    /// </summary>
    /// <param name="table">The table to check.</param>
    /// <param name="keyMembers">
    /// The collection of key members.  An attempt is always made to set this
    /// parameter to a valid value.
    /// </param>
    /// <param name="primaryKeyMember">
    /// The <see cref="EdmMember" /> that represents the integer primary key
    /// -OR- null if no such <see cref="EdmMember" /> exists.
    /// </param>
    /// <returns>
    /// Non-zero if the specified table has an integer primary key.
    /// </returns>
    private static bool IsIntegerPrimaryKey(
        EntitySetBase table,
        out ReadOnlyMetadataCollection<EdmMember> keyMembers,
        out EdmMember primaryKeyMember
        )
    {
        keyMembers = table.ElementType.KeyMembers;

        if (keyMembers.Count == 1) /* NOTE: The "rowid" only? */
        {
            EdmMember keyMember = keyMembers[0];
            PrimitiveTypeKind typeKind;

            if (MetadataHelpers.TryGetPrimitiveTypeKind(
                    keyMember.TypeUsage, out typeKind) &&
                (typeKind == PrimitiveTypeKind.Int64))
            {
                primaryKeyMember = keyMember;
                return true;
            }
        }

        primaryKeyMember = null;
        return false;
    }

    /// <summary>
    /// This method attempts to determine if all the specified key members have
    /// values available.
    /// </summary>
    /// <param name="translator">
    /// The <see cref="ExpressionTranslator" /> to use.
    /// </param>
    /// <param name="keyMembers">
    /// The collection of key members to check.
    /// </param>
    /// <param name="missingKeyMember">
    /// The first missing key member that is found.  This is only set to a valid
    /// value if the method is returning false.
    /// </param>
    /// <returns>
    /// Non-zero if all key members have values; otherwise, zero.
    /// </returns>
    private static bool DoAllKeyMembersHaveValues(
        ExpressionTranslator translator,
        ReadOnlyMetadataCollection<EdmMember> keyMembers,
        out EdmMember missingKeyMember
        )
    {
        foreach (EdmMember keyMember in keyMembers)
        {
            if (!translator.MemberValues.ContainsKey(keyMember))
            {
                missingKeyMember = keyMember;
                return false;
            }
        }

        missingKeyMember = null;
        return true;
    }

    /// <summary>
    /// Generates SQL fragment returning server-generated values.
    /// Requires: translator knows about member values so that we can figure out
    /// how to construct the key predicate.
    /// <code>
    /// Sample SQL:
    ///     
    ///     select IdentityValue
    ///     from dbo.MyTable
    ///     where @@ROWCOUNT > 0 and IdentityValue = scope_identity()
    /// 
    /// or
    /// 
    ///     select TimestamptValue
    ///     from dbo.MyTable
    ///     where @@ROWCOUNT > 0 and Id = 1
    /// 
    /// Note that we filter on rowcount to ensure no rows are returned if no rows were modified.
    /// </code>
    /// </summary>
    /// <param name="commandText">Builder containing command text</param>
    /// <param name="tree">Modification command tree</param>
    /// <param name="translator">Translator used to produce DML SQL statement
    /// for the tree</param>
    /// <param name="returning">Returning expression. If null, the method returns
    /// immediately without producing a SELECT statement.</param>
    /// <param name="wasInsert">
    /// Non-zero if this method is being called as part of processing an INSERT;
    /// otherwise (e.g. UPDATE), zero.
    /// </param>
    private static void GenerateReturningSql(StringBuilder commandText, DbModificationCommandTree tree,
        ExpressionTranslator translator, DbExpression returning, bool wasInsert)
    {
      // Nothing to do if there is no Returning expression
      if (null == returning) { return; }

      // select
      commandText.Append("SELECT ");
      returning.Accept(translator);
      commandText.AppendLine();

      // from
      commandText.Append("FROM ");
      tree.Target.Expression.Accept(translator);
      commandText.AppendLine();

      // where
#if USE_INTEROP_DLL && INTEROP_EXTENSION_FUNCTIONS
      commandText.Append("WHERE last_rows_affected() > 0");
#else
      commandText.Append("WHERE changes() > 0");
#endif

      EntitySetBase table = ((DbScanExpression)tree.Target.Expression).Target;
      ReadOnlyMetadataCollection<EdmMember> keyMembers;
      EdmMember primaryKeyMember;
      EdmMember missingKeyMember;

      // Model Types can be (at the time of this implementation):
      //      Binary, Boolean, Byte, DateTime, Decimal, Double, Guid, Int16,
      //      Int32, Int64,Single, String
      if (IsIntegerPrimaryKey(table, out keyMembers, out primaryKeyMember))
      {
          //
          // NOTE: This must be an INTEGER PRIMARY KEY (i.e. "rowid") table.
          //
          commandText.Append(" AND ");
          commandText.Append(GenerateMemberTSql(primaryKeyMember));
          commandText.Append(" = ");

          DbParameter value;

          if (translator.MemberValues.TryGetValue(primaryKeyMember, out value))
          {
              //
              // NOTE: Use the integer primary key value that was specified as
              //       part the associated INSERT/UPDATE statement.
              //
              commandText.Append(value.ParameterName);
          }
          else if (wasInsert)
          {
              //
              // NOTE: This was part of an INSERT statement and we know the table
              //       has an integer primary key.  This should not fail unless
              //       something (e.g. a trigger) causes the last_insert_rowid()
              //       function to return an incorrect result.
              //
              commandText.AppendLine("last_insert_rowid()");
          }
          else /* NOT-REACHED? */
          {
              //
              // NOTE: We cannot simply use the "rowid" at this point because:
              //
              //       1. The last_insert_rowid() function is only valid after
              //          an INSERT and this was an UPDATE.
              //
              throw new NotSupportedException(String.Format(
                  "Missing value for INSERT key member '{0}' in table '{1}'.",
                   (primaryKeyMember != null) ? primaryKeyMember.Name : "<unknown>",
                   table.Name));
          }
      }
      else if (DoAllKeyMembersHaveValues(translator, keyMembers, out missingKeyMember))
      {
          foreach (EdmMember keyMember in keyMembers)
          {
              commandText.Append(" AND ");
              commandText.Append(GenerateMemberTSql(keyMember));
              commandText.Append(" = ");

              // Retrieve member value SQL. the translator remembers member values
              // as it constructs the DML statement (which precedes the "returning"
              // SQL).
              DbParameter value;

              if (translator.MemberValues.TryGetValue(keyMember, out value))
              {
                  //
                  // NOTE: Use the primary key value that was specified as part the
                  //       associated INSERT/UPDATE statement.  This also applies
                  //       to composite primary keys.
                  //
                  commandText.Append(value.ParameterName);
              }
              else /* NOT-REACHED? */
              {
                  //
                  // NOTE: We cannot simply use the "rowid" at this point because:
                  //
                  //       1. This associated INSERT/UPDATE statement appeared to
                  //          have all the key members availab;e however, there
                  //          appears to be an inconsistency.  This is an internal
                  //          error and should be thrown.
                  //
                  throw new NotSupportedException(String.Format(
                      "Missing value for {0} key member '{1}' in table '{2}' " +
                      "(internal).", wasInsert ? "INSERT" : "UPDATE",
                      (keyMember != null) ? keyMember.Name : "<unknown>",
                      table.Name));
              }
          }
      }
      else if (wasInsert) /* NOT-REACHED? */
      {
          //
          // NOTE: This was part of an INSERT statement; try using the "rowid"
          //       column to fetch the most recently inserted row.  This may
          //       still fail if the table is a WITHOUT ROWID table -OR-
          //       something (e.g. a trigger) causes the last_insert_rowid()
          //       function to return an incorrect result.
          //
          commandText.Append(" AND ");
          commandText.Append(SqlGenerator.QuoteIdentifier("rowid"));
          commandText.Append(" = ");
          commandText.AppendLine("last_insert_rowid()");
      }
      else /* NOT-REACHED? */
      {
          //
          // NOTE: We cannot simply use the "rowid" at this point because:
          //
          //       1. The last_insert_rowid() function is only valid after
          //          an INSERT and this was an UPDATE.
          //
          throw new NotSupportedException(String.Format(
              "Missing value for UPDATE key member '{0}' in table '{1}'.",
               (missingKeyMember != null) ? missingKeyMember.Name : "<unknown>",
               table.Name));
      }
      commandText.AppendLine(";");
    }

    /// <summary>
    /// Lightweight expression translator for DML expression trees, which have constrained
    /// scope and support.
    /// </summary>
    private class ExpressionTranslator : DbExpressionVisitor
    {
      /// <summary>
      /// Initialize a new expression translator populating the given string builder
      /// with command text. Command text builder and command tree must not be null.
      /// </summary>
      /// <param name="commandText">Command text with which to populate commands</param>
      /// <param name="commandTree">Command tree generating SQL</param>
      /// <param name="preserveMemberValues">Indicates whether the translator should preserve
      /// member values while compiling t-SQL (only needed for server generation)</param>
      /// <param name="kind"></param>
      internal ExpressionTranslator(StringBuilder commandText, DbModificationCommandTree commandTree,
          bool preserveMemberValues, string kind)
      {
        Debug.Assert(null != commandText);
        Debug.Assert(null != commandTree);
        _kind = kind;
        _commandText = commandText;
        _commandTree = commandTree;
        _parameters = new List<DbParameter>();
        _memberValues = preserveMemberValues ? new Dictionary<EdmMember, DbParameter>() :
            null;
      }

      private readonly StringBuilder _commandText;
      private readonly DbModificationCommandTree _commandTree;
      private readonly List<DbParameter> _parameters;
      private readonly Dictionary<EdmMember, DbParameter> _memberValues;
      private int parameterNameCount = 0;
      private string _kind;

      internal List<DbParameter> Parameters { get { return _parameters; } }
      internal Dictionary<EdmMember, DbParameter> MemberValues { get { return _memberValues; } }

      // generate parameter (name based on parameter ordinal)
      internal SQLiteParameter CreateParameter(object value, TypeUsage type)
      {
        PrimitiveTypeKind primitiveType = MetadataHelpers.GetPrimitiveTypeKind(type);
        DbType dbType = MetadataHelpers.GetDbType(primitiveType);
        return CreateParameter(value, dbType);
      }

      // Creates a new parameter for a value in this expression translator
      internal SQLiteParameter CreateParameter(object value, DbType dbType)
      {
        string parameterName = string.Concat("@p", parameterNameCount.ToString(CultureInfo.InvariantCulture));
        parameterNameCount++;
        SQLiteParameter parameter = new SQLiteParameter(parameterName, value);
        parameter.DbType = dbType;
        _parameters.Add(parameter);
        return parameter;
      }

      #region Basics

      public override void Visit(DbApplyExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");

        VisitExpressionBindingPre(expression.Input);
        if (expression.Apply != null)
        {
          VisitExpression(expression.Apply.Expression);
        }
        VisitExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbArithmeticExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionList(expression.Arguments);
      }

      public override void Visit(DbCaseExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionList(expression.When);
        VisitExpressionList(expression.Then);
        VisitExpression(expression.Else);
      }

      public override void Visit(DbCastExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbCrossJoinExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        foreach (DbExpressionBinding binding in expression.Inputs)
        {
          VisitExpressionBindingPre(binding);
        }
        foreach (DbExpressionBinding binding2 in expression.Inputs)
        {
          VisitExpressionBindingPost(binding2);
        }
      }

      public override void Visit(DbDerefExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbDistinctExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbElementExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbEntityRefExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbExceptExpression expression)
      {
        VisitBinary(expression);
      }

      protected virtual void VisitBinary(DbBinaryExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        this.VisitExpression(expression.Left);
        this.VisitExpression(expression.Right);
      }

      public override void Visit(DbExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        throw new NotSupportedException("DbExpression");
      }

      public override void Visit(DbFilterExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Input);
        VisitExpression(expression.Predicate);
        VisitExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbFunctionExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionList(expression.Arguments);
        //if (expression.IsLambda)
        //{
        //  VisitLambdaFunctionPre(expression.Function, expression.LambdaBody);
        //  VisitExpression(expression.LambdaBody);
        //  VisitLambdaFunctionPost(expression.Function, expression.LambdaBody);
        //}
      }

      public override void Visit(DbGroupByExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitGroupExpressionBindingPre(expression.Input);
        VisitExpressionList(expression.Keys);
        VisitGroupExpressionBindingMid(expression.Input);
        VisitAggregateList(expression.Aggregates);
        VisitGroupExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbIntersectExpression expression)
      {
        VisitBinary(expression);
      }

      public override void Visit(DbIsEmptyExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbIsOfExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbJoinExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Left);
        VisitExpressionBindingPre(expression.Right);
        VisitExpression(expression.JoinCondition);
        VisitExpressionBindingPost(expression.Left);
        VisitExpressionBindingPost(expression.Right);
      }

      public override void Visit(DbLikeExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpression(expression.Argument);
        VisitExpression(expression.Pattern);
        VisitExpression(expression.Escape);
      }

      public override void Visit(DbLimitExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpression(expression.Argument);
        VisitExpression(expression.Limit);
      }

      public override void Visit(DbOfTypeExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbParameterReferenceExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
      }

      public override void Visit(DbProjectExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Input);
        VisitExpression(expression.Projection);
        VisitExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbQuantifierExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Input);
        VisitExpression(expression.Predicate);
        VisitExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbRefExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbRefKeyExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbRelationshipNavigationExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpression(expression.NavigationSource);
      }

      public override void Visit(DbSkipExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Input);
        foreach (DbSortClause clause in expression.SortOrder)
        {
          VisitExpression(clause.Expression);
        }
        VisitExpressionBindingPost(expression.Input);
        VisitExpression(expression.Count);
      }

      public override void Visit(DbSortExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpressionBindingPre(expression.Input);
        for (int i = 0; i < expression.SortOrder.Count; i++)
        {
          VisitExpression(expression.SortOrder[i].Expression);
        }
        VisitExpressionBindingPost(expression.Input);
      }

      public override void Visit(DbTreatExpression expression)
      {
        VisitUnaryExpression(expression);
      }

      public override void Visit(DbUnionAllExpression expression)
      {
        VisitBinary(expression);
      }

      public override void Visit(DbVariableReferenceExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
      }

      public virtual void VisitAggregate(DbAggregate aggregate)
      {
        if (aggregate == null) throw new ArgumentException("aggregate");
        VisitExpressionList(aggregate.Arguments);
      }

      public virtual void VisitAggregateList(IList<DbAggregate> aggregates)
      {
        if (aggregates == null) throw new ArgumentException("aggregates");
        for (int i = 0; i < aggregates.Count; i++)
        {
          VisitAggregate(aggregates[i]);
        }
      }

      public virtual void VisitExpression(DbExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        expression.Accept(this);
      }

      protected virtual void VisitExpressionBindingPost(DbExpressionBinding binding)
      {
      }

      protected virtual void VisitExpressionBindingPre(DbExpressionBinding binding)
      {
        if (binding == null) throw new ArgumentException("binding");
        VisitExpression(binding.Expression);
      }

      public virtual void VisitExpressionList(IList<DbExpression> expressionList)
      {
        if (expressionList == null) throw new ArgumentException("expressionList");
        for (int i = 0; i < expressionList.Count; i++)
        {
          VisitExpression(expressionList[i]);
        }
      }

      protected virtual void VisitGroupExpressionBindingMid(DbGroupExpressionBinding binding)
      {
      }

      protected virtual void VisitGroupExpressionBindingPost(DbGroupExpressionBinding binding)
      {
      }

      protected virtual void VisitGroupExpressionBindingPre(DbGroupExpressionBinding binding)
      {
        if (binding == null) throw new ArgumentException("binding");
        VisitExpression(binding.Expression);
      }

      protected virtual void VisitLambdaFunctionPost(EdmFunction function, DbExpression body)
      {
      }

      protected virtual void VisitLambdaFunctionPre(EdmFunction function, DbExpression body)
      {
        if (function == null) throw new ArgumentException("function");
        if (body == null) throw new ArgumentException("body");
      }

      //internal virtual void VisitRelatedEntityReference(DbRelatedEntityRef relatedEntityRef)
      //{
      //  VisitExpression(relatedEntityRef.TargetEntityReference);
      //}

      //internal virtual void VisitRelatedEntityReferenceList(IList<DbRelatedEntityRef> relatedEntityReferences)
      //{
      //  for (int i = 0; i < relatedEntityReferences.Count; i++)
      //  {
      //    VisitRelatedEntityReference(relatedEntityReferences[i]);
      //  }
      //}

      protected virtual void VisitUnaryExpression(DbUnaryExpression expression)
      {
        if (expression == null) throw new ArgumentException("expression");
        VisitExpression(expression.Argument);
      }
      #endregion

      public override void Visit(DbAndExpression expression)
      {
        VisitBinary(expression, " AND ");
      }

      public override void Visit(DbOrExpression expression)
      {
        VisitBinary(expression, " OR ");
      }

      public override void Visit(DbComparisonExpression expression)
      {
        Debug.Assert(expression.ExpressionKind == DbExpressionKind.Equals,
            "only equals comparison expressions are produced in DML command trees in V1");

        VisitBinary(expression, " = ");

        RegisterMemberValue(expression.Left, expression.Right);
      }

      /// <summary>
      /// Call this method to register a property value pair so the translator "remembers"
      /// the values for members of the row being modified. These values can then be used
      /// to form a predicate for server-generation (based on the key of the row)
      /// </summary>
      /// <param name="propertyExpression">DbExpression containing the column reference (property expression).</param>
      /// <param name="value">DbExpression containing the value of the column.</param>
      internal void RegisterMemberValue(DbExpression propertyExpression, DbExpression value)
      {
        if (null != _memberValues)
        {
          // register the value for this property
          Debug.Assert(propertyExpression.ExpressionKind == DbExpressionKind.Property,
              "DML predicates and setters must be of the form property = value");

          // get name of left property 
          EdmMember property = ((DbPropertyExpression)propertyExpression).Property;

          // don't track null values
          if (value.ExpressionKind != DbExpressionKind.Null)
          {
            Debug.Assert(value.ExpressionKind == DbExpressionKind.Constant,
                "value must either constant or null");
            // retrieve the last parameter added (which describes the parameter)
            _memberValues[property] = _parameters[_parameters.Count - 1];
          }
        }
      }

      public override void Visit(DbIsNullExpression expression)
      {
        expression.Argument.Accept(this);
        _commandText.Append(" IS NULL");
      }

      public override void Visit(DbNotExpression expression)
      {
        _commandText.Append("NOT (");
        expression.Accept(this);
        _commandText.Append(")");
      }

      public override void Visit(DbConstantExpression expression)
      {
        SQLiteParameter parameter = CreateParameter(expression.Value, expression.ResultType);
        _commandText.Append(parameter.ParameterName);
      }

      public override void Visit(DbScanExpression expression)
      {
        string definingQuery = MetadataHelpers.TryGetValueForMetadataProperty<string>(expression.Target, "DefiningQuery");
        if (definingQuery != null)
        {
          throw new NotSupportedException(String.Format("Unable to update the EntitySet '{0}' because it has a DefiningQuery and no <{1}> element exists in the <ModificationFunctionMapping> element to support the current operation.", expression.Target.Name, _kind));
        }
        _commandText.Append(SqlGenerator.GetTargetTSql(expression.Target));
      }

      public override void Visit(DbPropertyExpression expression)
      {
        _commandText.Append(GenerateMemberTSql(expression.Property));
      }

      public override void Visit(DbNullExpression expression)
      {
        _commandText.Append("NULL");
      }

      public override void Visit(DbNewInstanceExpression expression)
      {
        // assumes all arguments are self-describing (no need to use aliases
        // because no renames are ever used in the projection)
        bool first = true;
        foreach (DbExpression argument in expression.Arguments)
        {
          if (first) { first = false; }
          else { _commandText.Append(", "); }
          argument.Accept(this);
        }
      }

      private void VisitBinary(DbBinaryExpression expression, string separator)
      {
        _commandText.Append("(");
        expression.Left.Accept(this);
        _commandText.Append(separator);
        expression.Right.Accept(this);
        _commandText.Append(")");
      }
    }
  }
}

