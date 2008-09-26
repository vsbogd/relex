/*
 * Copyright 2008 Novamente LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package relex;

import java.io.Serializable;
import java.util.ArrayList;

import relex.feature.Atom;

/**
 * The Document class stores a sequence of Sentence objects.
 * It is primarily useful for any post-processing steps, anthing
 * that needs to obtain access multiple sentences at a time.
 *
 */
public class Document extends Atom implements Serializable
{
	private static final long serialVersionUID = -4518792541801263127L;

	// Unique ID string identifying this document.
	private String idString;

	// Sequence of sentences
	private ArrayList<Sentence> sentences;

	/* -------------------------------------------------------------------- */
	/* Constructors, and setters/getters for private members. */
	// Constructor.
	public Document()
	{
		sentences = null;
	}

	public String getIDString()
	{
		return idString;
	}

	public void setIDString(String str)
	{
		idString = str;
	}

	public void addSentence(Sentence sntc)
	{
		sentences.add(sntc);
	}

} // end Document
